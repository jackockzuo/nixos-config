# 疑难杂症：omercore 守护进程崩溃循环（systemd 226/NAMESPACE）

- 日期：2026-08-25
- 状态：✅ 已解决
- 影响范围：omercore daemon 从未成功启动（重启计数 32+），EC 看门狗/风扇/功耗保持全部失效
- 涉及文件：
  - `modules/omencore.nix`（`omencore.service` 的 systemd 单元配置）

---

## 症状

1. `systemctl status omencore`：`activating (auto-restart)`，`code=exited, status=226/NAMESPACE`，`RestartSec=5` 无限循环；
2. journalctl 关键行：
   ```
   omencore.service: Failed to set up mount namespacing: /var/tmp/omencore: No such file or directory
   omencore.service: Failed at step NAMESPACE spawning ... (code=exited, status=226/NAMESPACE)
   ```
3. ExecStartPre 的 `mkdir -p /var/tmp/omencore` 同样报 226/NAMESPACE（`(mkdir)[5145]` 进程都没能 spawn）。

## 环境

- NixOS 26.11，systemd 253+（namespace 防护默认开启）
- omencore 4.1.7 服务单元：`PrivateTmp=true` + `ReadWritePaths=["/var/run" "/var/log" "/sys/kernel/debug/ec" "/var/tmp/omencore"]` + `ExecStartPre=mkdir -p /var/tmp/omencore` + `ProtectSystem=strict`

## 排查过程（时间线 + 关键证据）

### 1. 确认循环与错误类型
```bash
systemctl status omencore --no-pager    # restart counter 32, 226/NAMESPACE
journalctl -u omencore --no-pager | tail
```
- 错误固定在"mount namespacing"阶段（在 spawn 任何进程之前），指向 `/var/tmp/omencore` 不存在。

### 2. 确认目录确实不存在
```bash
ls -ld /var/tmp/omencore   # No such file or directory
ls -ld /var/tmp            # 存在（sticky 权限正常）
```

### 3. 对照 systemd 生命周期推演
- systemd 单元执行顺序：**搭建 mount namespace（处理 ReadWritePaths/PrivateTmp）→ 才执行 ExecStartPre → ExecStart**；
- `ReadWritePaths=/var/tmp/omencore` 需要在 namespace 搭建时 bind-mount 该路径，但目录还不存在 → 直接 226/NAMESPACE；
- `PrivateTmp=true` 又把 `/var/tmp` 私有化为空挂载——即使 mkdir 有机会跑，写的也是私有 tmp 里的目录，与 ReadWritePaths 指向的宿主路径对不上，双重错误。

## 根因分析

| # | 问题 | 直接原因 | 深层原因 |
|---|---|---|---|
| 1 | 服务 226/NAMESPACE 崩溃循环 | `ReadWritePaths=/var/tmp/omencore` 指向不存在的目录 | systemd 在 ExecStartPre **之前**搭建 namespace 就要 bind-mount 该路径；"先 mkdir 再写"的顺序根本不成立 |
| 2 | 症状长期隐藏 | 服务从未成功启动，但失败不影响登录/桌面 | `Restart=on-failure` + 静默循环，不主动看 journalctl 不会发现 |
| 3 | 设计反模式 | 手工 mkdir + ReadWritePaths 组合 | systemd 原生 `StateDirectory`/`RuntimeDirectory`/`CacheDirectory` 会在 namespace 搭建前自动创建目录，才是正路 |

## 修复方案（已固化）

`modules/omencore.nix`（`omencore.service` serviceConfig）：

| 改动 | 说明 |
|---|---|
| 删除 `ExecStartPre = mkdir -p /var/tmp/omencore` | 目录交给 systemd 管理，不再手工 mkdir |
| 新增 `StateDirectory = "omencore"` | systemd 在 namespace 搭建前自动创建 `/var/lib/omencore`（root 所有、namespace 内可写），彻底消除顺序问题 |
| `DOTNET_BUNDLE_EXTRACT_BASE_DIR`：`/var/tmp/omencore` → `/var/lib/omencore` | .NET 单文件解压缓存目录跟随 StateDirectory |
| 删除 `PrivateTmp = true` | 与 ReadWritePaths 组合必炸；本服务无需要私有 tmp 的理由 |
| `ReadWritePaths` 移除 `/var/tmp/omencore` | 由 StateDirectory 接管 |

- 应用：`sudo nixos-rebuild switch --flake .#omen`。
- 验证：`systemctl status omencore` = `active (running)` 不再循环；`ls -ld /var/lib/omencore` 自动创建；`journalctl -u omencore` 无 NAMESPACE 错误。

## 经验教训（防再犯）

1. **systemd 单元禁止"先 mkdir 再写路径"**：ExecStartPre 在 namespace 搭建**之后**才运行；ReadWritePaths/StateDirectory 声明的路径必须在单元启动前就存在。
2. **需要可写目录 → 用 `StateDirectory`/`RuntimeDirectory`/`CacheDirectory`**：systemd 保证在 namespace 搭建前创建，正确性由 systemd 兜底，不依赖 ExecStartPre 顺序。
3. **`PrivateTmp=true` 与 `ReadWritePaths=/var/tmp/xxx` 组合必炸**：PrivateTmp 把 /var/tmp 私有化为空目录，宿主路径永远"不存在"——两者互斥，不要同用。
4. **服务 226/NAMESPACE 循环重启**：第一时间看 journalctl 里 `Failed to set up mount namespacing: <路径>` 行，报错的路径就是缺失/不可挂载的路径，直接指向问题。
5. **`Restart=on-failure` 会静默掩盖服务从未工作**：关键守护进程（尤其硬件控制类）要定期 `systemctl status` 检查。

## 遗留事项（TODO）

- [ ] daemon 首次稳定运行后，确认 EC `--hold` 生效（`omencore-cli diagnose` 里 unit 状态不再是 "not installed"）；之后 EC 功耗/性能档保持由 daemon 看门狗接管。
