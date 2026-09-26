# 会话归档：DMS → Noctalia v5 桌面迁移 + 配色单一来源 + 中文字体（2026-09-26）

> 本文件为一次性会话工作总结与存档，非 STANDARDS 规则。
> 前置背景：DMS（DankMaterialShell/quickshell）→ Noctalia v5（原生 C++/Wayland shell）迁移收尾。

---

## 1. 目标（用户原话收敛）

- DMS 残留清零，锁屏切 Noctalia 内置，壳层动态取色（随壁纸）保留。
- 配色散落的 hex 收口为单一来源；界面中文字体换 LXGW Neo XiHei，拉丁零回归。
- GUI 里的设计成果（bar/锁屏布局）不因迁移丢失。

## 2. 关键决策与实现

### 锁屏：Noctalia 内置，零 PAM 配置
- 源码实证 `/tmp/noctalia src/shell/lockscreen/lock_screen.cpp:1105`：`pamService = "login"`
  硬编码 → 认证走系统 `login` PAM（NixOS 默认提供）。**不要**加 `security.pam.services.*`。
- hyprlock 全链路退役：模块/import/PAM 服务/catppuccin 端口/文档引用清零；
  `swayidle.sh` 改 `noctalia msg session lock`（10min 锁 / 15min 屏 / 30min 挂起，logind 兜底）。
- GUI 里设计的 5 组件锁屏布局经提升进 Nix（见 §3）。

### 配色：`my.catppuccin.palette` 单一来源
- `flake.nix` 增加 8 色 Mocha palette attrset；niri（focus-ring/border/recent-windows）与
  fastfetch（title/output + 分组 keyColor）全部改引用，裸 hex 归零。
- 新增颜色时一律走 palette 追加，禁止在使用点写 hex。

### 动态取色：保留壳层，禁掉模板写回
- `theme.source = "wallpaper"`（壳层 bar/面板/锁屏随壁纸取色）——用户决策，保留。
- `theme.templates.builtin_ids = [ ]`：Noctalia 模板引擎会**写回** kitty/niri/gtk/qt/starship
  等**生成文件**（kitty include 行、niri include、gtk css），与 catppuccin/HM 声明式管理打架——
  与已废除的 DMS 写回 hack 同构，故整体禁用。某 app 要跟壁纸时再按需加 id。
- GUI 覆盖层（`~/.local/state/noctalia/settings.toml`）中已提升的段必须删除：state 文件是
  overrides 层（`config_service.cpp:557`），**同名键 state 恒赢**，不删则 Nix 设置假死。
  **删除时序坑（实测）**：`bar.default` 与 `lockscreen_widgets` 是 shell 的一等运行时状态，
  config_service 监听 state 目录，外部改写后把内存值重新落盘 → 运行中手删这两段会被原样写回。
  正确顺序：先 `nr` + 重启会话（新 base 已含提升值），再删；此后若被重写也是同值，无害。

### 字体：LXGW Neo XiHei
- `fc-scan` 确认 family 串为 `LXGW Neo XiHei`（satty/fonts.conf 用此精确串）。
- A/B 实测（改前/改后 fontconfig 实例）：中文 Noto CJK → LXGW ✓，拉丁 Inter 零回归 ✓。

### GUI → Nix 提升工作流（见 noctalia.nix 顶部注释）
GUI 调一次记录精确键名 → 提升进 settings（checkConfig 构建期校验兜底）→ 删 state 段。
本次提升清单：
- 共享层（noctalia.nix）：`theme`、`bar.default`、`notification`、`shell.panel`、
  `widget.launcher`、`widget.tray`（含 drawer；死随机 Id `7EVqkROMq6` 不提升）
- **主机剖面**（hosts/omen/hm.nix）：`lockscreen_widgets` —— 绑定 HDMI-A-1/1080p，
  按 STANDARDS §0.5（共享层禁机器痕迹）放主机层，先例同 niri 输出段
- 留在 GUI 层：`wallpaper`（日常随 GUI 换，非设计基线）

### DMS 残留清理（两处口子）
- 常规：DMS 包/窗口规则/注释/`~/.config/DankMaterialShell`/`~/.cache/quickshell`。
- **GTK 注入残留**（易漏，实体文件非 HM symlink，switch 后永久滞留）：
  `~/.config/gtk-3.0/dank-colors.css`、`~/.config/gtk-3.0/gtk.css`（@import dank-colors）、
  `~/.config/gtk-4.0/gtk.css`（237KB MD3 ripple + 全量 libadwaita @define-color 转储）。
  已入 `cleanStaleNoctaliaResidue` activation，带内容特征守卫（防误删未来用户 css）。

## 3. 验证（全绿 + 证据链）

- `noctalia config validate` 在 **HM 构建期**执行（HM 模块 checkConfig，home-module.nix:129），
 HM generation 构建通过 = 所有提升键通过 schema 校验。
- 产物取证：生成的 config.toml（theme/builtin_ids=[]）、niri config.kdl（palette hex 落盘）、
  kitty.conf 零 noctalia 引用、activation 脚本含清理逻辑、lxgw 字体进 toplevel 闭包。
- 门禁：`nix fmt` / `git diff --check` / `nix flake check` / toplevel 构建 / HM generation 构建。
- switch 后待实测：锁屏 PAM 认证、锁屏布局恢复、GTK 清理效果、中文界面、idle 链。

## 4. 遗留与手动步骤

- **`nr` + 重启会话后**（顺序重要，见 §2 删除时序坑）：
  1. 删 `~/.local/state/noctalia/settings.toml` 中 `[bar.default]` 与 `[lockscreen_widgets]`
     两段（此时 base 已含提升值，删后声明式真正接管；本轮已先删掉 notification /
     shell.panel / widget.launcher / widget.tray 四段）。
  2. 现场实测：锁屏 PAM 认证、锁屏布局恢复、GTK 清理效果、中文界面、idle 链。
- `/var/lib/dms-greeter`（DMS greeter 状态目录）需 sudo 删除：
  `sudo rm -rf /var/lib/dms-greeter`。事实修正存档：**非空目录**（btrfs 目录 size=条目字节，
  242B ≈ ≥1 文件），属主 greeter:greeter 0750，ran 不可读；构建产物 /etc 零引用 → 删后不会重建。
  现役目录是 tmpfiles 声明的 `/var/lib/noctalia-greeter`（10-noctalia-greeter.conf）。
- Noctalia greeter 用户/组（uid 999）是 greetd 标准做法（modules/desktop.nix），**不是**残留，勿删。

## 5. 教训（本轮事故级误判复盘）

1. **否定性证据需要第二方法复核**：`grep -r` 不跟符号链接，而 NixOS 的 /etc 全是符号链接——
   曾据「空 grep」误判 toplevel 闭包不含 HM generation（实际在，`home-manager.service` 用户单元
   ExecStart 引用它），差点写进 STANDARDS 冗余门禁。空 grep/空输出 ≠ 不存在，须 `ls -la`/
   `nix-store -q --requisites` 等独立方法交叉确认。
2. **btrfs 目录非空判据**：目录 `size=242` 是条目字节数（ext4 恒为 4096 不可比），`nlink=1`
   表示无子目录。判空须读内容，无权限时不能下「空目录」结论。
3. **HM 侧门禁覆盖机制**（澄清，无需加门禁）：`startAsUserService = true` → home-manager.service
   用户单元引用 activationPackage → generation 进 toplevel 闭包 → `nix build toplevel` 必然构建
   HM 并触发 checkConfig。仅当 CI 只跑 `nix flake check`（不构建）时才存在盲区。
