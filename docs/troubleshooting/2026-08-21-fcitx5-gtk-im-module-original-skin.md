# 疑难杂症：Ctrl+P 等 GTK/Electron 应用候选框显示 fcitx5 原皮（默认皮肤）

- 日期：2026-08-21
- 状态：✅ 已解决
- 影响范围：Wayland 原生 GTK3/4 应用（Chromium/Electron 家族：浏览器打印对话框、VSCode 命令面板等）中输入中文时，候选框显示 fcitx5 默认样式而非 Catppuccin 主题
- 涉及文件：
  - `home/modules/desktop/appearance.nix`（gtk3/gtk4.extraConfig）
  - `home/modules/desktop/fcitx5.nix`（注释同步）
  - `docs/troubleshooting/2026-08-21-fcitx5-gtk-im-module-original-skin.md`（本文档）
  - `STANDARDS.md`（§4 防再犯要点）

## 症状

在按 Ctrl+P 唤起的应用（Chromium/Electron 家族：浏览器打印、VSCode 命令面板、ChatGPT 等）中输入中文时，fcitx5 候选框显示**默认白底黑字样式**（“原皮”），未应用 Catppuccin Mocha 主题。其他应用（如 kitty 终端）候选框主题正常。

## 环境

- HP OMEN 16（x86_64-linux，niri 合成器，Wayland 会话）
- fcitx5 5.1.21 + rime-ice（雾凇）拼音
- 主题：catppuccin-fcitx5（`catppuccin-mocha-mauve`）
- 运行系统代：gen-46（修复前）

## 排查过程（时间线 + 关键证据）

1. **理论排查**：主题名被怀疑写错。
   - 取证：`nix eval .#legacyPackages.x86_64-linux.catppuccin-fcitx5.outPath` → 主题目录列表确认
     `catppuccin-mocha-mauve` **确实存在** → 排除“主题名拼错”。
2. **运行环境取证**（关键证据）：
   - fcitx5 进程（PID）environ 显示 `XDG_DATA_DIRS` 含
     `/nix/store/...-fcitx5-with-addons-5.1.21/share`，且该 store 路径下
     `share/fcitx5/themes/` 里确有 `catppuccin-mocha-mauve` → **主题可达**，排除“主题目录丢失”。
   - `fcitx5-diagnose` 输出：addons 全部加载、库全部找到、3 个 UI addon 启用 → 排除“插件未装载”。
3. **机制定位**：fcitx wiki《Using Fcitx 5 on Wayland》原文——
   "Setting `GTK_IM_MODULE=fcitx` … it is necessary **if your compositor does not support
   Wayland input method frontend**"；且全局 GTK_IM_MODULE 在 Wayland 下会触发
   **候选框闪烁/异常**（"Candidate window is blinking under wayland with Fcitx 5"）。
   仓库注释早已声明“不设全局 GTK_IM_MODULE”，但 **`gtk3/gtk4.extraConfig` 写入的
   `~/.config/gtk-3.0/settings.ini` / `gtk-4.0/settings.ini` 的 `gtk-im-module=fcitx`
   对 Wayland 与 X11 同时生效**——这两个文件把前脚关掉的路又用后脚打开了：
   Wayland 原生 GTK 被迫加载 fcitx 的 GTK IM 模块 → 候选框改为**应用内嵌渲染**
   （不经合成器 text-input-v3 通道）→ 内嵌样式不受 classicui 浮窗 Theme 控制 → “原皮”。

## 根因分析

- 直接原因：`gtk3.extraConfig` / `gtk4.extraConfig` 里的 `gtk-im-module = "fcitx"`
  以 settings.ini 形式全局生效（**不分后端**），强制 Wayland 原生 GTK3/4 应用
  走 fcitx GTK IM 模块的应用内嵌候选框。
- 深层原因：对“GTK_IM_MODULE 环境变量不全局设置”的现代写法理解到位，
  但漏掉了 **settings.ini 级 `gtk-im-module` 是同样的全局通道**——错误地以为
  extraConfig 只影响 XWayland 应用（fcitx5.nix 注释原文如此表述）。
- 为什么之前没发现：kitty/终端类应用不走 GTK IM 模块（走 GLFW/合成器通道），
  主题正常，掩盖了 GTK 应用族的异常；且此类应用此前多在 XWayland 模式下，
  XWayland 走 fcitx 内嵌是预期行为，切换至 Wayland 原生后才暴露。

## 修复方案

1. `appearance.nix`：
   - `gtk3.extraConfig = { };`、`gtk4.extraConfig = { };`（**不再写 gtk-im-module**）
     - Wayland 原生 GTK3/4 → 自动走合成器 text-input-v3（niri 支持）→
       classicui 浮窗渲染 → Catppuccin 主题生效
     - XWayland GTK3 → GTK3 内建 XIM（XMODIFIERS 全局 `@im=fcitx` 已在 locale.nix 设置）
   - `gtk2.extraConfig` **保留** `"gtk-im-module=\"fcitx\""`（GTK2 仅 X11/XWayland，无 text-input，必须经 fcitx IM 模块）
2. `fcitx5.nix`：2b 注释同步为“按后端拆分”表述（不再声称 extraConfig 只影响 XWayland）。
3. 验证：`nixos-rebuild dry-build --flake .#omen` exit 0；`nix fmt` 0 changed；
   `git diff --check` 干净。

## 恢复流程（回退本次修复）

若某 XWayland GTK3 应用出现输入法失效（理论上 GTK3 内建 XIM 应兜底）：

```nix
# appearance.nix —— 临时恢复（仅当 XWayland GTK3 输入异常时）
gtk3.extraConfig = {
  gtk-im-module = "fcitx";
};
```

恢复后重新 `sudo nixos-rebuild switch`。

## 经验教训（防再犯）

1. **GTK 输入法有三条通道，配置时全都要过一遍脑子**：
   - `GTK_IM_MODULE` 环境变量（全局，Wayland 下禁用）
   - `settings.ini` 的 `gtk-im-module`（全局，Wayland 下同样生效——本事故）
   - 合成器 text-input-v3（Wayland 原生唯一正路）
   “只设一处”会给自己留后门，标准应明确：**GTK3/4 任何形式都不设 im-module**。
2. 现代写法的判断标准是**官方 wiki 的“是否必要”条件句**，不是社区模板的抄写——
   本事故中 fcitx wiki 明示只有合成器不支持 text-input 时才需要 GTK_IM_MODULE。
3. 排查 IM 问题时按“可达性→装载→通道”三层次取证（本事故：主题可达→插件装载→
   渲染通道），不要停在“主题名对不对”这一层。

## 遗留事项（TODO）

- [ ] 观察 XWayland GTK3 应用（如有）输入法是否受 XIM 兜底正常，异常则按“恢复流程”局部回退
- [ ] 执行 `sudo nixos-rebuild switch --flake .#omen` 后在真实会话二次确认（dry-build 只验证可构建）