# 疑难杂症记录（Troubleshooting Log）

> 本目录记录本机（omen）发生过的真实故障与排查过程，一病一档。
> 目的：下次遇到同类症状可快速定位；沉淀排查方法论，避免重复踩坑。

## 约定

- 目录结构：`docs/troubleshooting/<日期>-<症状关键词>.md`
- 文件名：`YYYY-MM-DD-症状英文短词.md`（如 `2026-08-17-niri-login-sops-password.md`）
- 内容语言：中文（与本仓库 README/STANDARDS 一致）
- 每条记录必须包含：症状 → 排查证据 → 根因 → 修复 → 经验教训 → 遗留事项
- 新增记录后，在下方索引表加一行；涉及配置改动的，同步核对 STANDARDS.md 是否需要更新

## 索引

| 日期 | 症状 | 根因摘要 | 状态 | 文档 |
|---|---|---|---|---|
| 2026-08-17 | niri 登录失败：输对密码报错 + 进不去桌面 | ① sops 密码链失效（shadow 哈希与秘密不符）② 旧内核未重启导致 nouveau 在跑 + 会话变量强制 nvidia → niri 崩溃 ③ greetd initial_session 配置冲突 | ✅ 已解决（含遗留项） | [2026-08-17-niri-login-sops-password.md](./2026-08-17-niri-login-sops-password.md) |
| 2026-08-17 | kitty 毛玻璃消失（配置文件正常） | niri `config.kdl` 在无用户会话期间被覆盖成默认模板，丢失 `include "blur.kdl"` 等全部 include；覆盖者未 100% 锁定（最可能 DMS greeter 运行时边界情况） | ✅ 已解决（含监控项） | [2026-08-17-niri-config-kdl-overwritten.md](./2026-08-17-niri-config-kdl-overwritten.md) |
| 2026-08-17 | DMS 切换壁纸动态主题生成失败 | matugen config.toml 缺 `[config]` 段（matugen 4.x 必须存在，可为空）→ dry-run 直接解析用户配置报 `missing field 'config'` | ✅ 已解决 | [2026-08-17-matugen-config-section-missing.md](./2026-08-17-matugen-config-section-missing.md) |
| 2026-08-18 | Distrobox 容器内 fish 报 "Unknown command" | HM enableFishIntegration 生成无条件集成脚本，容器挂载 $HOME+ /nix 后"脚本在、工具不在" PATH → 报 Unknown command；改用 `type -q` 守卫（fish 3.3 兼容） | ✅ 已解决 | [2026-08-18-distrobox-container-fish-unknown-command.md](./2026-08-18-distrobox-container-fish-unknown-command.md) |
| 2026-08-21 | Ctrl+P 等 GTK/Electron 应用候选框显示 fcitx5 原皮 | gtk3/gtk4.extraConfig 写入 settings.ini 的 `gtk-im-module=fcitx` 对 Wayland 与 X11 同时生效——Wayland 原生 GTK 被迫用 fcitx GTK IM 模块 → 应用内嵌候选框（不经合成器 text-input-v3）→ 不受 classicui 主题控制 | ✅ 已解决 | [2026-08-21-fcitx5-gtk-im-module-original-skin.md](./2026-08-21-fcitx5-gtk-im-module-original-skin.md) |

## 模板（新增记录时复制）

```markdown
# 疑难杂症：<一句话症状>

- 日期：YYYY-MM-DD
- 状态：✅ 已解决 / ⏳ 进行中 / ❌ 未解决
- 影响范围：<什么功能/服务受影响>
- 涉及文件：<仓库内改动文件清单>

## 症状

## 环境

## 排查过程（时间线 + 关键证据）
（记录：查了什么日志、跑了什么命令、发现了什么证据；日志摘录要带命令来源）

## 根因分析
（分层写：直接原因 → 深层原因 → 为什么之前没发现）

## 修复方案
（配置改动逐个列出；附验证方式）

## 恢复流程（若需要 live ISO / 救援环境）
（可复用的恢复命令，让下次能照着做）

## 经验教训（防再犯）

## 遗留事项（TODO）
```

## 相关资源

- 恢复脚本：[fix-password.sh](./fix-password.sh)（2026-08-17 密码救援脚本，live ISO / nixos-enter 通用）
- 配置准则：[STANDARDS.md](../../STANDARDS.md)
