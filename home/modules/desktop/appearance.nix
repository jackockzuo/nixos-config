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

  # ---- 1. fastfetch 定制系统信息面板 ----
  # 效果：终端启动时显示彩色键名的树状信息面板（OS/KER/PAK/AGE/USR/WM/DES/SHE/TER/PC/CPU/MEM/SWP/GPU/MON/DIS）
  # logo：kitty-direct 原生协议渲染官方 NixOS 彩色雪花（store 路径注入，见上方 let）
  xdg.configFile."fastfetch/config.jsonc" = {
    text = builtins.replaceStrings [ "@NIXOS_LOGO_PATH@" ] [ logoPath ] fastfetchConfig;
    force = true; # 覆盖原作者旧配置
  };
  xdg.configFile."fastfetch/nixos-logo.png" = {
    source = ../../source/beautify/fastfetch/nixos-logo.png;
    force = true;
  };

  # ---- 2. fontconfig 字体渲染 ----
  # 效果：全局抗锯齿 + hintslight 微调 + 中文回退（Noto Sans CJK SC）
  # 字体分工：终端 Maple Mono（kitty 显式指定）、等宽代码 JetBrainsMono、UI/中文 Noto Sans CJK SC
  xdg.configFile."fontconfig/fonts.conf" = {
    source = ../../source/beautify/fontconfig/fonts.conf;
    force = true; # 覆盖原作者旧配置
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
    # 🔴 输入法按应用声明（fcitx wiki 2025-09 现代写法）：
    # 全局 GTK_IM_MODULE 不再设置（Wayland 原生 GTK3/4 自动走 text-input-v3，
    # 全局设置反而触发候选框闪烁）；仅 X11/XWayland 的 GTK 应用需要
    # gtk-im-module=fcitx，经 extraConfig 合并进 HM 生成的 settings.ini。
    # 注意：gtk2.extraConfig 是字符串类型（~/.gtkrc-2.0 语法，多行用 \n 连接），
    # gtk3/4 是 attrset。
    gtk2.extraConfig = "gtk-im-module=\"fcitx\"";
    gtk3.extraConfig = { gtk-im-module = "fcitx"; };
    gtk4.extraConfig = { gtk-im-module = "fcitx"; };
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
