# 疑难杂症：Ctrl+P 等 GTK/Electron 应用候选框显示 fcitx5 原皮（默认皮肤）

- 日期：2026-08-21
- 状态：✅ 已解决
- 影响范围：Wayland 原生 GTK3/4 应用（Chromium/Electron 家族：浏览器打印对话框、VSCode 命令面板等）中输入中文时，候选框显示 fcitx5 默认样式而非 Catppuccin 主题
- 涉及文件：
  - `home/modules/desktop/appearance.nix`（gtk3/gtk4.extraConfig）
  - `home/modules/desktop/fcitx5.nix`（注释同步）
  - `modules/locale.nix`（系统层 `environment.variables.GTK_IM_MODULE = lib.mkForce ""`）
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

**两层根因（第一层修完“重启后仍复现”，第二层才是最终因）：**

- 直接原因（第一层）：`gtk3.extraConfig` / `gtk4.extraConfig` 里的
  `gtk-im-module = "fcitx"` 以 settings.ini 形式全局生效（**不分后端**），
  强制 Wayland 原生 GTK3/4 应用走 fcitx GTK IM 模块的内嵌候选框。
  → 已在 appearance.nix 清除（gtk3/4 置空，gtk2 保留）。
- 🔴 **深层原因（第二层，重启后仍复现的真正原因）**：**NixOS 官方 fcitx5
  模块自动注入全局 `GTK_IM_MODULE=fcitx`**——
  `nixos/modules/i18n/input-method/fcitx5.nix` 的 `environment.variables`：
  ```nix
  environment.variables = {
    XMODIFIERS = "@im=fcitx";
    GTK_IM_MODULE = "fcitx";   # ← 官方模块写死
    ...
  };
  ```
  它经 `/etc/profile` → `set-environment` 注入**所有登录会话**，优先级高于
  HM 层的 settings.ini——即使我们清了 HM 层，系统会话变量仍在，Wayland
  原生 GTK 应用依旧被强制 fcitx GTK IM 模块。仓库内全量 grep 找不到它
  （不在本仓库），必须查 `/nix/store/...-set-environment` 才能看到。
- 为什么之前没发现：只查了本仓库配置（locale.nix/env.nix/config.kdl）与 HM
  层，未排查系统会话变量生成物（set-environment / pam environment）；fcitx
  官方 wiki 只指明“合成器不支持 text-input 才需要设置”，而 NixOS 模块的
  默认注入恰好与该现代建议相悖，是个隐蔽的官方默认行为。

## 修复方案（三层，缺一不可）

1. **HM 层 GTK（第一层）** `appearance.nix`：
   - `gtk3.extraConfig = { };`、`gtk4.extraConfig = { };`（**不再写 gtk-im-module**）
     - Wayland 原生 GTK3/4 → 自动走合成器 text-input-v3（niri 支持）→
       classicui 浮窗渲染 → Catppuccin 主题生效
     - XWayland GTK3 → GTK3 内建 XIM（XMODIFIERS 全局 `@im=fcitx` 已在 locale.nix 设置）
   - `gtk2.extraConfig` **保留** `"gtk-im-module=\"fcitx\""`（GTK2 仅 X11/XWayland，无 text-input，必须经 fcitx IM 模块）
   - `fcitx5.nix`：2b 注释同步为“按后端拆分”表述。
2. **系统层 GTK（第二层——NixOS 官方模块自动注入）** `modules/locale.nix`：
   - `environment.variables.GTK_IM_MODULE = lib.mkForce "";`
     - NixOS 官方 fcitx5 模块（`nixos/modules/i18n/input-method/fcitx5.nix`）
       通过 `environment.variables` 无条件写 `GTK_IM_MODULE = "fcitx"`（见 `environment.variables = { ... GTK_IM_MODULE = "fcitx"; ... }`），
       经 `/etc/profile → set-environment` 注入**所有登录会话**（本机实测
       `set-environment` 第 13 行 `export GTK_IM_MODULE="fcitx"`）。
     - `lib.mkForce ""` 把它覆盖为 unset（GTK 源码空串等同未设）——
       Wayland 原生 GTK 走 text-input-v3，XWayland GTK3 走内建 XIM。
3. **系统层 Qt（第三层——DMS Spotlight 原皮真根因）** `modules/locale.nix`：
   - `environment.sessionVariables.QT_IM_MODULES = "wayland;fcitx";`
     - 用户按 Mod+P 唤起的 **DMS Spotlight = quickshell = Qt6 应用**，由 **systemd user
       服务**启动，**只继承登录会话环境**——niri config.kdl 的 environment 块
       **喂不到它**（niri 官方 wiki《Application-Specific Issues》原文）。
     - 此前 `QT_IM_MODULES="wayland;fcitx"` 只写在 niri config.kdl（合成器 spawn 层），
       系统层只有 `QT_IM_MODULE=fcitx` → Qt6 加载 fcitx-qt IM 模块 → **应用内嵌
       候选框**（不经合成器 text-input-v3 → classicui 浮窗）→ 原皮。
     - `QT_IM_MODULES`（Qt 6.7+ 官方变量）放系统层后：合成器 text-input-v3 优先
       （niri 支持 → classicui 渲染 → Catppuccin 主题生效），fcitx 兜底 Qt4/5。
4. 验证：`nixos-rebuild dry-build --flake .#omen` exit 0；`nix fmt` 0 changed；
   `git diff --check` 干净；`nix eval` 确认：
   - `environment.variables.GTK_IM_MODULE` 求值为空串（官方注入已覆盖）
   - `environment.sessionVariables.QT_IM_MODULES` 求值为 `"wayland;fcitx"`（新补）

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

1. **GTK 输入法有四条通道，配置时全都要过一遍脑子**：
   - `GTK_IM_MODULE` **环境变量**（全局）——这里包括两层：
     a. 我们自己写的（已在 locale.nix 移除）
     b. **官方模块自动注入的**（NixOS fcitx5 模块 `environment.variables` 写死）
        — 本事故真正的持久层！查 `set-environment` 运行时文件才能看到，仓库 grep 不到
   - `settings.ini` 的 `gtk-im-module`（全局，Wayland 下同样生效——本事故第一层）
   - 合成器 text-input-v3（Wayland 原生唯一正路）
   “只设一处”会给自己留后门，标准应明确：**GTK3/4 任何形式都不设 im-module**，
   且要**主动检查官方模块是否偷偷设了**（fcitx5 官方默认就是设了）。
2. 现代写法的判断标准是**官方 wiki 的“是否必要”条件句**，不是社区模板的抄写——
   本事故中 fcitx wiki 明示只有合成器不支持 text-input 时才需要 GTK_IM_MODULE。
3. 排查 IM 问题时按“可达性→装载→通道→**运行时注入**”四层次取证（本事故：
   主题可达→插件装载→渲染通道→**set-environment 里官方模块注入的变量**），
   不只看仓库文件，要查 `/nix/store/*-set-environment` 实际运行产物。
4. **“重启后仍复现”= 一定还有某个持久注入源没排掉**——不要重复怀疑已排查过的
   层，直接沿登录会话链（environ 逐级对比）找第一次出现该变量的进程。

## 遗留事项（TODO）

- [ ] 观察 XWayland GTK3 应用（如有）输入法是否受 XIM 兜底正常，异常则按“恢复流程”局部回退
- [ ] 执行 `sudo nixos-rebuild switch --flake .#omen` 后在真实会话二次确认（dry-build 只验证可构建）