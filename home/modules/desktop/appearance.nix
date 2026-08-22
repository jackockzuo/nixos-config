{ pkgs, ... }:

let
  # fastfetch 配置文件模板：部署时把 logo 占位符替换为 Nix 路径引用的 store 路径。
  # 🔴 不用相对路径：fastfetch 的 source 相对路径按 cwd 解析，从其他目录运行会
  #    "Failed to resolve logo source" → 回退内置 ASCII logo。
  #    `${../../source/...}` 在 Nix 求值时自动转为 /nix/store/... 绝对路径，
  #    不依赖用户名/home 目录，迁移或换用户也不用改。
  fastfetchConfig = builtins.readFile ../../source/beautify/fastfetch/config.jsonc;
  logoPath = toString ../../source/beautify/fastfetch/nixos-logo.png;
in
{
  # ============================================================
  # appearance.nix —— 桌面外观（fastfetch/字体渲染/GTK 主题/光标）
  # 注意：source 相对路径基于本文件位置（modules/desktop/）
  # ============================================================

  xdg.configFile = {
    # ---- 1. fastfetch 定制系统信息面板 ----
    # 效果：终端启动时显示彩色键名的树状信息面板（OS/KER/PAK/AGE/USR/WM/DES/SHE/TER/PC/CPU/MEM/SWP/GPU/MON/DIS）
    # logo：kitty-direct 原生协议渲染官方 NixOS 彩色雪花（store 路径注入，见上方 let）
    "fastfetch/config.jsonc" = {
      text = builtins.replaceStrings [ "@NIXOS_LOGO_PATH@" ] [ logoPath ] fastfetchConfig;
      force = true; # 覆盖原作者旧配置
    };
    "fastfetch/nixos-logo.png" = {
      source = ../../source/beautify/fastfetch/nixos-logo.png;
      force = true;
    };

    # ---- 2. fontconfig 字体渲染 ----
    # 效果：全局抗锯齿 + hintslight 微调 + 中文回退（Noto Sans CJK SC）
    # 字体分工：终端 Maple Mono（kitty 显式指定）、等宽代码 JetBrainsMono、UI/中文 Noto Sans CJK SC
    "fontconfig/fonts.conf" = {
      source = ../../source/beautify/fontconfig/fonts.conf;
      force = true; # 覆盖原作者旧配置
    };
  };

  # ---- 3. GTK 全局统一主题 (Catppuccin Mocha) ----
  # gtk4.theme = null：显式采用 HM 26.05+ 新默认（gtk4 不再跟随 gtk3 主题），
  # 消除 stateVersion < 26.05 时的弃用警告
  gtk = {
    enable = true;
    gtk4.theme = null;
    theme = {
      name = "Catppuccin-Mocha-Standard-Mauve-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        variant = "mocha";
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    # 🔴 输入法 IM 模块按后端拆分（fcitx wiki 2025-09 现代写法 + STANDARDS §4）：
    #  - GTK3/4 settings.ini 不再写 gtk-im-module：这行【Wayland 与 X11 都会读】，
    #    写了会让 Wayland 原生 GTK3/4（Chromium/Electron 等）被迫加载 fcitx GTK IM 模块，
    #    改用应用内嵌候选框（不过合成器 text-input-v3 通道）→ 显示 GTK 内嵌默认样式
    #    （“原皮”），而不是 classicui 浮窗的 Catppuccin 主题（2026-08-21 实测修复）。
    #    niri 支持 text-input-v3 → 原生 Wayland GTK 应用自动走合成器通道，主题生效。
    #  - GTK2 保留“gtk-im-module=fcitx”：GTK2 只有 X11/XWayland，必须经 fcitx IM 模块。
    #  - XWayland 的 GTK3 应用：走 GTK3 内建 XIM（XMODIFIERS 全局已设 @im=fcitx，locale.nix）。
    gtk2.extraConfig = "gtk-im-module=\"fcitx\"";
    gtk3.extraConfig = { }; # 空：不强制 IM 模块（Wayland 原生走 text-input-v3；XWayland 走内建 XIM）
    gtk4.extraConfig = { }; # 空：同上（GTK4 X11 亦走内建 XIM）
  };

  # ---- 3b. QT 全局主题（Qt6 应用跟随 GTK 主题）----
  # niri 环境变量已设 QT_QPA_PLATFORMTHEME=gtk3（source/niri/config.kdl），
  # 这里声明式补全 Qt6 的 platformTheme，纯 Qt6 应用（如部分 KDE 系工具）也能跟主题。
  # 注意：platformTheme.name = "gtk3" 是原生 Qt GTK3 插件（新版 HM 的 "gtk" 已弃用）
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "adwaita-dark";
  };

  # ---- 4. 鼠标光标（Catppuccin Mocha Mauve） ----
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-mauve-cursors";
    package = pkgs.catppuccin-cursors.mochaMauve;
    size = 24;
  };
}
