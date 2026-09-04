# NixOS 配置（多主机可移植）

单仓库：系统级（`modules/`）+ 用户级（`home/`）+ 主机剖面（`hosts/<machine>/`）。
当前主机：`omen`（HP OMEN 16-wf0xxx，用户 `ran`）。
**唯一权威依据**：`STANDARDS.md`。会话记录/事故档案见 `docs/`。

## 仓库布局

```
flake.nix         hosts 清单驱动 nixosConfigurations（现 #omen）；身份 my 注入
hosts/omen/       机器专属：hardware-config / hardware / omencore(性能解锁) / performance / hm.nix
modules/          平台无关系统层（11 文件 + default.nix 聚合地图）
home/             平台无关用户层（home-manager）
packages/omencore OmenCore CLI 打包（官方 release zip）
docs/             troubleshooting + 升级清单 + 会话归档
```

- 共享层**禁止**机器专属/第三方痕迹（STANDARDS §0.5 红线）：新增机器 = `flake.nix` hosts
  清单一行 + `hosts/<name>/` 一个目录（`nixos-generate-config` 生成其 hardware-configuration.nix）。
- 每机 hostname/hostId 由 hosts 清单注入 `my`；身份（username/stateVersion）全仓共用。

## 常用操作（omen）

```bash
nr            # = snapper 快照 + sudo nixos-rebuild switch --flake ~/nixos-config#omen
nix flake check          # 质量门禁（treefmt/deadnix/statix）
nix fmt                  # 统一格式化（RFC 风格）
```

## 代理（最终模型：dae 透明接管，主机专属）

- `hosts/omen/proxy.nix`：内核层透明代理（dae）——**所有应用零配置**（Chrome/CLI/任意 App）。
  geoip/geosite 判断国内直连（无名单遗漏），非国内走后端节点 fcclient（socks5://127.0.0.1:7892）。
- 行为：fcclient 开 → 外网通；fcclient 关 → 国内直连照常、外网不可达（后端 down）。
- 终端 fish `proxy on [port] / off`（可选，供无 dae 场景/显式控制用）。
- 此模块仅 omen 主机 import（共享层保持纯净可移植）；曾用的 Chrome 启动器/系统代理 hack 已移除。

> 实验/弃用结论（TUN、gsettings、静态名单等）见 `docs/2026-09-05-portability-proxy-session.md`。

> 这些均为用户级/私有实现（`~/.local/share/applications/`、`~/.config/fish/functions/`、
> `~/Documents/nix-packaging/fcclient`），不进本仓库 —— 保持系统配置纯净可移植。
> 曾尝试的 TUN 全局限 / 系统代理跟随 / fcclient 自带开关，均因权限、UX 或环境问题弃用，
> 结论与实验见 `docs/2026-09-05-portability-proxy-session.md`。

## 质量门禁（STANDARDS §7/§10）

`nix fmt` → `nix flake check` → `git diff --check` → rebuild 无新 warning；
改动涉及主机剖面/共享层移动时同步 README/STANDARDS。CI = 前四件事（GitHub Actions）。

## 验证状态

- ✅ 多主机结构（hosts 清单驱动）+ 共享层零 fcclient/dae/OMEN 痕迹
- ✅ omencore CLI-only 性能解锁保留（omen-power-unlock tpl=5 / hold）
- ✅ thermald 移除（OMEN16 无 DPTF，启动即失败）；BBR+fq 通用化
- ✅ switch 后服务/包/网络/桌面核查通过
- ⏸ 新构建待日常使用验证后 tag（合并已入 main，见 git log）
