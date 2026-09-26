{
  pkgs,
  lib,
  my,
  ...
}:

let
  # fastfetch logo：store 路径引用（不用相对路径，fastfetch 按 cwd 解析会失败）
  logoPath = toString ../../source/beautify/fastfetch/nixos-logo.png;

  # 图标主题合并包：Papirus 为主 + Tela-circle 兜底
  # 图标主题按 index.theme Inherits 链回退查找（GTK/Qt/Noctalia 同一机制）
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

  # Catppuccin GTK 主题包（v2 引擎；gtk3 主题名 + gtk4 CSS 注入共用此包）
  catppuccinGtk = pkgs.catppuccin-gtk.override {
    accents = [ my.catppuccin.accent ];
    variant = my.catppuccin.flavor;
  };
in
{
  # ============================================================
  # appearance.nix —— 桌面外观（fastfetch/字体渲染/GTK 主题/光标）
  # ============================================================

  xdg.configFile = {
    # fontconfig 字体渲染（全局抗锯齿 + hintslight + 中文 LXGW Neo XiHei，Noto CJK 兜底）
    # fontconfig 无结构化模块接口，fonts.conf 保留 source 文件声明
    "fontconfig/fonts.conf" = {
      source = ../../source/beautify/fontconfig/fonts.conf;
      force = true; # 覆盖原作者旧配置
    };

    # GTK4/libadwaita CSS 注入（Catppuccin 官方方法）：libadwaita 拒读 gtk-theme-name，
    # 唯一样式入口是 ~/.config/gtk-4.0/gtk.css，缺失时 GTK4 应用为原版 Adwaita。
    # 已知代价：libadwaita 大版本升级可能局部样式错位，删掉这三个链接即回退原状。
    "gtk-4.0/gtk.css".source =
      "${catppuccinGtk}/share/themes/${my.catppuccin.names.gtk}/gtk-4.0/gtk.css";
    "gtk-4.0/gtk-dark.css".source =
      "${catppuccinGtk}/share/themes/${my.catppuccin.names.gtk}/gtk-4.0/gtk-dark.css";
    "gtk-4.0/assets" = {
      source = "${catppuccinGtk}/share/themes/${my.catppuccin.names.gtk}/gtk-4.0/assets";
      recursive = true; # 目录源必须显式递归
    };
  };

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
          title = my.catppuccin.palette.text; # Title color 主机名的颜色
          output = my.catppuccin.palette.text;
        };
      };
      # 各分组 keyColor = Mocha 色板引用（my.catppuccin.palette 单一来源）
      modules = [
        "break"
        {
          type = "os";
          key = "OS";
          keyColor = my.catppuccin.palette.green;
        }
        {
          type = "kernel";
          key = " ├  KER ";
          keyColor = my.catppuccin.palette.green;
        }
        {
          type = "packages";
          key = " ├  PAK ";
          format = "{all}";
          keyColor = my.catppuccin.palette.green;
        }
        {
          type = "command";
          key = " ├  AGE ";
          text = "birth_install=$(stat -c %W / 2>/dev/null || stat -f %B /); current=$(date +%s); days_difference=$(( (current - birth_install) / 86400 )); echo $days_difference days";
          keyColor = my.catppuccin.palette.green;
        }
        {
          type = "title";
          key = " └  USR ";
          keyColor = my.catppuccin.palette.green;
        }
        "break"
        {
          type = "wm";
          key = "WM";
          keyColor = my.catppuccin.palette.sapphire;
        }
        {
          type = "de";
          key = " ├  DES ";
          keyColor = my.catppuccin.palette.sapphire;
        }
        {
          type = "shell";
          key = " ├  SHE ";
          keyColor = my.catppuccin.palette.sapphire;
        }
        {
          type = "terminal";
          key = " ├  TER ";
          keyColor = my.catppuccin.palette.sapphire;
        }
        {
          type = "terminalfont";
          key = " └  TFO ";
          keyColor = my.catppuccin.palette.sapphire;
        }
        "break"
        {
          type = "host";
          key = "PC ";
          keyColor = my.catppuccin.palette.teal;
        }
        {
          type = "cpu";
          key = " ├  CPU ";
          format = "{1} @ {7}"; # 完整型号 + 睿频（不截断内容）
          keyColor = my.catppuccin.palette.teal;
        }
        {
          type = "memory";
          key = " ├  MEM ";
          keyColor = my.catppuccin.palette.teal;
        }
        {
          type = "swap";
          key = " ├  SWP ";
          keyColor = my.catppuccin.palette.teal;
        }
        {
          type = "gpu";
          key = " ├  GPU ";
          format = "{1} {2}"; # 完整 GPU 型号（不截断）
          keyColor = my.catppuccin.palette.teal;
        }
        {
          type = "monitor";
          key = " ├  MON ";
          format = "{width}x{height}@{refresh-rate}"; # 分辨率 + 刷新率
          keyColor = my.catppuccin.palette.teal;
        }
        {
          type = "disk";
          key = " └  DIS ";
          keyColor = my.catppuccin.palette.teal;
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
      name = my.catppuccin.names.gtk; # 派生名单一来源（flake.nix my.catppuccin.names，须与 v2 包实际目录名一致）
      package = catppuccinGtk; # 同一包实例：主题目录 + gtk4 CSS 注入来源
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

  # 明暗主题：固定 dark（Noctalia theme.mode=dark，见 home/modules/desktop/noctalia.nix）
  # 其余应用一律固定 Catppuccin（my.catppuccin）
  home = {
    activation = {
      # 迁移清理（2026-08-28）：删除旧 xdg.configFile 部署的 nixos-logo.png
      # 新 settings.logo.source 直接引用 store 路径，此文件不再被引用
      cleanStaleFastfetchLogo = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        if [ -L "$HOME/.config/fastfetch/nixos-logo.png" ]; then
          $DRY_RUN_CMD rm "$HOME/.config/fastfetch/nixos-logo.png"
        fi
      '';

      # 迁移清理：已下线的 matugen 动态配色链路（模板/config/生成物）
      cleanStaleMatugen = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        $DRY_RUN_CMD rm -f "$HOME/.config/fish/colors.matugen.fish"
        for f in "$HOME/.config/matugen/config.toml" "$HOME/.config/matugen/templates/fish-colors.fish.template"; do
          if [ -L "$f" ]; then
            $DRY_RUN_CMD rm "$f"
          fi
        done
      '';
    };

    # 鼠标光标（配色名/包由 catppuccin.cursors 提供，见 home/modules/theme/）
    pointerCursor = {
      enable = true;
      gtk.enable = true;
      x11.enable = true;
      size = 30; # 全桌面统一光标尺寸（niri cursor.xcursor-size 引用此处，单一来源）
    };
  };
}
