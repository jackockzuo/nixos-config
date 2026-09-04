{ pkgs, lib, ... }:

let
  # fastfetch logo：store 路径引用（不用相对路径，fastfetch 按 cwd 解析会失败）
  logoPath = toString ../../source/beautify/fastfetch/nixos-logo.png;

  # 图标主题合并包：Papirus 为主 + Tela-circle 兜底
  # 图标主题按 index.theme Inherits 链回退查找（GTK/Qt/Quickshell 同一机制）
  papirusWithTelaFallback = pkgs.runCommand "papirus-icon-theme-with-tela-fallback" { } ''
    mkdir -p $out/share/icons
    for t in Papirus Papirus-Dark Papirus-Light; do
      case $t in
        Papirus)       fb=Tela-circle ;;
        Papirus-Dark)  fb=Tela-circle-dark ;;
        Papirus-Light) fb=Tela-circle-light ;;
      esac
      mkdir -p $out/share/icons/$t
      ln -s ${pkgs.papirus-icon-theme}/share/icons/$t/* $out/share/icons/$t/
      # index.theme 替换为真实文件并改写 Inherits（其余子目录保持 store symlink，不复制体积）
      rm $out/share/icons/$t/index.theme
      cp ${pkgs.papirus-icon-theme}/share/icons/$t/index.theme $out/share/icons/$t/index.theme
      sed -i "s|^Inherits=.*|Inherits=$fb,hicolor|" $out/share/icons/$t/index.theme
    done
    for t in Tela-circle Tela-circle-dark Tela-circle-light; do
      ln -s ${pkgs.tela-circle-icon-theme}/share/icons/$t $out/share/icons/$t
    done
    # hicolor 终极兜底（papirus 自带同名目录）
    ln -s ${pkgs.papirus-icon-theme}/share/icons/hicolor $out/share/icons/hicolor
  '';
in
{
  # ============================================================
  # appearance.nix —— 桌面外观（fastfetch/字体渲染/GTK 主题/光标）
  # ============================================================

  xdg.configFile = {
    # fontconfig 字体渲染（全局抗锯齿 + hintslight + 中文回退 Noto Sans CJK SC）
    # fontconfig 无结构化模块接口，fonts.conf 保留 source 文件声明
    "fontconfig/fonts.conf" = {
      source = ../../source/beautify/fontconfig/fonts.conf;
      force = true; # 覆盖原作者旧配置
    };
  };

  # 迁移清理（2026-08-28）：删除旧 xdg.configFile 部署的 nixos-logo.png
  # 新 settings.logo.source 直接引用 store 路径，此文件不再被引用(REF:2026-08-28-fastfetch-cleanup)
  home.activation.cleanStaleFastfetchLogo = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/fastfetch/nixos-logo.png" ]; then
      $DRY_RUN_CMD rm "$HOME/.config/fastfetch/nixos-logo.png"
    fi
  '';

  # fastfetch 定制系统信息面板
  # logo：kitty-direct 原生协议渲染 NixOS 彩色雪花（store 绝对路径）
  # 模块同时安装 fastfetch 二进制
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        type = "kitty-direct"; # kitty 原生图片协议(24bit)，比 sixel 锐利无抖动
        source = logoPath; # 官方彩色雪花（store 绝对路径）
        width = 34; # 宽度 34：图片约 16 行高，匹配右侧完整文本(15 行信息)高度
        padding = {
          top = 3; # logo 上移 1 行
          left = 1;
          right = 1;
        };
      };
      display = {
        separator = " "; # 键与值之间分隔符
        color = {
          title = "#bfc9c3"; # Title color 主机名的颜色
          output = "#bfc9c3";
        };
      };
      modules = [
        "break"
        {
          type = "os";
          key = "OS";
          keyColor = "#88d6bb";
        }
        {
          type = "kernel";
          key = " ├  KER ";
          keyColor = "#88d6bb";
        }
        {
          type = "packages";
          key = " ├  PAK ";
          format = "{all}";
          keyColor = "#88d6bb";
        }
        {
          type = "command";
          key = " ├  AGE ";
          text = "birth_install=$(stat -c %W / 2>/dev/null || stat -f %B /); current=$(date +%s); days_difference=$(( (current - birth_install) / 86400 )); echo $days_difference days";
          keyColor = "#88d6bb";
        }
        {
          type = "title";
          key = " └  USR ";
          keyColor = "#88d6bb";
        }
        "break"
        {
          type = "wm";
          key = "WM";
          keyColor = "#a8cbe2";
        }
        {
          type = "de";
          key = " ├  DES ";
          keyColor = "#a8cbe2";
        }
        {
          type = "shell";
          key = " ├  SHE ";
          keyColor = "#a8cbe2";
        }
        {
          type = "terminal";
          key = " ├  TER ";
          keyColor = "#a8cbe2";
        }
        {
          type = "terminalfont";
          key = " └  TFO ";
          keyColor = "#a8cbe2";
        }
        "break"
        {
          type = "host";
          key = "PC ";
          keyColor = "#cee9dd";
        }
        {
          type = "cpu";
          key = " ├  CPU ";
          format = "{1} @ {7}"; # 完整型号 + 睿频（不截断内容）
          keyColor = "#cee9dd";
        }
        {
          type = "memory";
          key = " ├  MEM ";
          keyColor = "#cee9dd";
        }
        {
          type = "swap";
          key = " ├  SWP ";
          keyColor = "#cee9dd";
        }
        {
          type = "gpu";
          key = " ├  GPU ";
          format = "{1} {2}"; # 完整 GPU 型号（不截断）
          keyColor = "#cee9dd";
        }
        {
          type = "monitor";
          key = " ├  MON ";
          format = "{width}x{height}@{refresh-rate}"; # 分辨率 + 刷新率
          keyColor = "#cee9dd";
        }
        {
          type = "disk";
          key = " └  DIS ";
          keyColor = "#cee9dd";
        }
        "break"
        "colors"
      ];
    };
  };

  # GTK 全局统一主题 (Catppuccin Mocha)
  # gtk4.theme = null：显式采用 HM 26.05+ 新默认，消除弃用警告
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
      package = papirusWithTelaFallback; # Papirus 主 + Tela-circle 兜底（见上方 let）
    };
    # 🔴 输入法 IM 模块按后端拆分（fcitx wiki 2025-09 + STANDARDS §4）：
    #  GTK3/4 settings.ini 不再写 gtk-im-module（写了会退回应用内嵌候选框="原皮"）(REF:2026-08-21-fcitx5-gtk)
    #  GTK2 保留 gtk-im-module=fcitx（仅 X11/XWayland）
    gtk2.extraConfig = "gtk-im-module=\"fcitx\"";
    gtk3.extraConfig = { }; # 空：不强制 IM 模块（Wayland 原生走 text-input-v3；XWayland 走内建 XIM）
    gtk4.extraConfig = { }; # 空：同上（GTK4 X11 亦走内建 XIM）
  };

  # QT 全局主题（Qt6 应用跟随 GTK 主题）
  # niri 环境变量已设 QT_QPA_PLATFORMTHEME=gtk3，这里补全 Qt6 platformTheme
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "adwaita-dark";
  };

  # 暗/亮主题手动切换（Mod+Shift+L 见 niri-binds.nix）
  # 切换内容见 theme-switch 头部注释（DMS 模式/GTK/Qt/图标/光标全套跟随）

  # 鼠标光标（Catppuccin Mocha Mauve）
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-mauve-cursors";
    package = pkgs.catppuccin-cursors.mochaMauve;
    size = 24;
  };
}
