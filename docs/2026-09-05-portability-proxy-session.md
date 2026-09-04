# 会话归档：多主机可移植重构 + 代理模型定型（2026-09-04 ~ 09-05）

> 本文件为一次性会话工作总结与存档，非 STANDARDS 规则。涉及三处：
> ① nixos-config（分支 `feat/portability-cleanup`，未并入 main）
> ② 私有 flake `~/Documents/nix-packaging/fcclient`（fcclient / fcclient-root）
> ③ 用户级文件（fish 函数、桌面项）

---

## 1. 目标（用户原话收敛）

- nixos-config 可移植到任意电脑（不绑定 OMEN 16）；第三方程序（fcclient 等）不进系统配置。
- 保留 OMEN 性能解锁（功耗墙 0xBA=5）。
- 代理：fcclient 关闭时无任何接管/环境残留、国内自由访问；需要时 CLI/浏览器可用代理。

## 2. 已完成：可移植重构（nixos-config）

分支 `feat/portability-cleanup`（基于 main=e9510ce，main 未动），提交：
- `d5173bf` wip 基线快照（重构前在途改动，防丢失）
- `5a669d1` 多主机 + 第三方清理 + omencore CLI 瘦身
- `0f1507c` pkexec setuid 通用化（GUI 提权工具基础设施）
- `a50edc2` 移除 thermald（OMEN16 无 DPTF，启动即失败，冗余）

结构变更：
- `hosts/omen/` 新主机剖面：hardware-configuration.nix / hardware.nix / omencore.nix / performance.nix / hm.nix（fish perf-*、niri 输出段 eDP/HDMI）
- `modules/` 只剩平台无关通用层；删除 `proxy.nix`（dae/fcclient 路由、端口、pname 规则）、系统包 `dae`、nix-daemon http_proxy；BBR+fq 通用化迁入 network.nix（ip_forward 随 dae 移除）
- `omercore` CLI-only：删 GUI/桌面项/pkexec wrapper/omen-hardware-perms/wheel-EC 权限；保留 `omen-power-unlock`（0xBA=5）+ daemon 看门狗（实测 omencore-cli 单文件可独立运行）
- `flake.nix` hosts 清单驱动 `nixosConfigurations`；hostname/hostId 由清单注入 my
- `STANDARDS.md`：适用多主机、§0.5 第三方红线、§1 hosts 剖面规则、[OMEN] 节对齐 CLI 实现、§6 多机 age key
- `modules/desktop.nix` 补 `security.polkit.enablePkexecWrapper = true`（通用 pkexec 能力）

验证（omen 机上）：`nix flake check` 全绿；toplevel 构建成功；switch 后服务/包/网络核查通过；
`omercore-cli status` = performance / tpl=5 / hold=True。

## 3. 已完成：fcclient 代理模型定型（最终形态，非 TUN）

**最终采用：内核透明代理（dae，hosts/omen/proxy.nix）** —— 所有应用零配置，geoip/geosite 国内直连（无名单遗漏），非国内走 fcclient(socks5://169.254.0.1:7892) 后端。
关键修复链（2026-09-05 实测）：dae group 需 `policy: fixed(0)`；daens 无法访问宿主 127.0.0.1/局域网(回环缺失+rp_filter)；宿主侧 dae0 需配 169.254.0.1/30（systemd dae-host-addr 固化）后后端拨通（google 204 / github 200 / baidu 直连 200）。
当前该机浏览器/CLI 均零配置透明代理；fcclient 关 = 外网不可达、国内照常。
曾试过的 TUN/系统代理/静态名单等方案结论保留于 §4。

| 对象 | 机制（均为用户级/私有，不进 nixos-config） | 行为 |
|---|---|---|
| fcclient | 原菜单项直接启动（或私有 flake） | 想代理就开，不想就关 |
| Chrome | 用户级桌面项 `~/.local/share/applications/google-chrome.desktop`：固定 `--proxy-server=http://127.0.0.1:7892` + `--proxy-bypass-list`（国内域名直连） | fcclient 开 → 外网通；关 → 国内直连、外网打不开（本来也没代理） |
| 终端 CLI | fish 函数 `~/.config/fish/functions/proxy.fish`：`proxy on [port]` / `proxy off` / `proxy status` | 只影响当前 shell，端口可自定义并记忆 |

要点：
- 不再依赖 gsettings 系统代理 / 会话环境变量 / 菜单包装（均已清理：fcclient（代理）桌面项、fcclient-gui-proxy 脚本、gsettings 还原 none）。
- Chrome 固定代理的理由：fcclient 自带的"系统代理"开关不改 gsettings 也不写 env（实测无效）；Chrome 在 niri 会话不读 gsettings（需 XDG_CURRENT_DESKTOP=GNOME 才读，亦不稳定）→ 用固定 flag 最确定。

私有 flake `~/Documents/nix-packaging/fcclient` 状态：
- `default`（原 GUI 包，buildFHSEnv 自 .deb，含 libepoxy/JDK/托盘等）
- `fcclient-root`（pkexec 包装，用于 TUN 探索，当前**未采用**，保留备用）
- 系统配置已含通用 pkexec（0f1507c），如需 root 方案可用。

## 4. 过程中验证过但放弃的路径（备忘）

- AppImage（fmapp-linux-lite/dist，fcclient 3.1.8）：headless 7892 代理可用；GUI 因 appimage-run FHS 缺 libepoxy 无窗口 → 弃用。
- TUN/虚拟网卡全局限：普通用户 `TUNSETIFF: Operation not permitted`；fcclient-root（root）可行但 fcclient 内部反复弹管理员密码、UX 不可用 → 放弃 TUN。
- fcclient"系统代理"开关：不写 gsettings、不写 env → 对 Chrome 无效。
- Chrome+gsettings（manual + XDG_CURRENT_DESKTOP=GNOME）：headless 验证可行，但依赖"启动时机/菜单条目"，体验脆弱 → 改为固定 flag。

## 5. 待办 / 待你决策

- [ ] 在 omen 机上验收通过后：`git checkout main && git merge feat/portability-cleanup && git tag vX.Y.Z`
- [ ] Chrome 菜单重开后验证外网/国内行为（若菜单未刷新，注销一次）
- [ ] 换电脑时：`hosts/<name>/` + flake 清单一行 + `.sops.yaml` 加 age key（见 STANDARDS）
- [ ] fcclient-root（root/TUN）默认不启用，保留备查
