# NixOS 配置（多主机可移植）

单仓库：系统级（`modules/`）+ 用户级（`home/`）+ 主机剖面（`hosts/<machine>/`）。
当前主机：`omen`（HP OMEN 16-wf0xxx，用户 `ran`）。
**唯一权威依据**：`STANDARDS.md`。会话记录/事故档案见 `docs/`。

## 仓库布局

```
flake.nix         hosts 清单驱动 nixosConfigurations（现 #omen）；身份 my 注入
hosts/omen/       机器专属：hardware-config / hardware / omencore(性能解锁) / performance / hm.nix
modules/          平台无关系统层（11 文件 + default.nix 聚合地图；仅 root/服务必需包 + fonts）
home/             平台无关用户层（home-manager）
  modules/desktop GUI 应用 + 桌面会话工具（packages.nix）、niri/kitty/fcitx5/dms…
  modules/tools   通用 CLI（shell-utils）、监控（monitoring）、开发（dev）、yazi/nixvim…
  source/         用户级静态资产（fastfetch/fontconfig/niri scripts/dms themes）
assets/           系统级静态资产（Limine 主题 / 壁纸）
packages/omencore OmenCore CLI 打包（官方 release zip）
docs/             troubleshooting + 升级清单 + 会话归档
```

- **包/配置落点判定树见 `STANDARDS.md` §3.1**：系统层只留 root/服务必需；
  GUI 与通用 CLI 归 `home/`；程序专属依赖随程序文件；同一包全仓只声明一次。

- 共享层**禁止**机器专属/第三方痕迹（STANDARDS §0.5 红线）：新增机器 = `flake.nix` hosts
  清单一行 + `hosts/<name>/` 一个目录（`nixos-generate-config` 生成其 hardware-configuration.nix）。
- 每机 hostname/hostId 由 hosts 清单注入 `my`；身份（username/stateVersion）全仓共用。

## 常用操作（omen）

```bash
# ── 重建 ──
nr              # 重建并切换（快照 / + /home → nh 构建/包差异/切换；不改 inputs）
nr -u           # 先更新全部 flake inputs 再重建（升级 nixpkgs/依赖）
nr -U nixpkgs   # 只更新指定 input
nr -n           # 干跑（只看会做什么，不切换）

# ── 全量升级 ──
tg              # topgrade：非 NixOS 升级 + 调用 nr -u（= 全量更新 + 重建）

# ── 清理 ──
clean-system    # GC（保留最近 15 代 / 14 天）

# ── 回滚 ──
nh os rollback  # 回退到上一代（或 snapper rollback）

# ── 提交前门禁 ──
nix fmt && nix flake check && git diff --check
```

> 三条命令职责单一：`nr` = 重建、`tg` = 全量升级、`clean-system` = 清理；NixOS 统一走 `nh`。

## 代理（最终模型：dae 透明接管，主机专属）

- `hosts/omen/proxy.nix`：内核层透明代理（dae）——**所有应用零配置**（Chrome/CLI/任意 App）。
  geoip/geosite 判断国内直连（无名单遗漏），非国内走后端节点 fcclient（socks5://127.0.0.1:7892）。
- 行为：fcclient 开 → 外网通；fcclient 关 → 国内直连照常、外网不可达（后端 down）。
- 终端 fish `proxy on [port] / off`（可选，供无 dae 场景/显式控制用）。
- 此模块仅 omen 主机 import（共享层保持纯净可移植）；曾用的 Chrome 启动器/系统代理 hack 已移除。

> 实验/弃用结论（TUN、gsettings、静态名单等）见 `docs/troubleshooting/2026-09-05-portability-proxy-session.md`。

> 这些均为用户级/私有实现（`~/.local/share/applications/`、`~/.config/fish/functions/`、
> `~/Documents/nix-packaging/fcclient`），不进本仓库 —— 保持系统配置纯净可移植。
> 曾尝试的 TUN 全局限 / 系统代理跟随 / fcclient 自带开关，均因权限、UX 或环境问题弃用，
> 结论与实验见 `docs/troubleshooting/2026-09-05-portability-proxy-session.md`。

## 质量门禁（STANDARDS §7/§10）

`nix fmt` → `nix flake check` → `git diff --check` → rebuild 无新 warning；
改动涉及主机剖面/共享层移动时同步 README/STANDARDS。CI = 前四件事（GitHub Actions）。

## 验证状态

- ✅ 多主机结构（hosts 清单驱动）+ 共享层零 fcclient/dae/OMEN 痕迹
- ✅ omencore CLI-only 性能解锁保留（omen-power-unlock tpl=5 / hold）
- ✅ thermald 移除（OMEN16 无 DPTF，启动即失败）；BBR+fq 通用化
- ✅ switch 后服务/包/网络/桌面核查通过
- ⏸ 新构建待日常使用验证后 tag（合并已入 main，见 git log）
