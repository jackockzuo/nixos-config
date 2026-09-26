# ============================================================
# niri.nix —— 合成器（wayland.windowManager.niri 官方模块）
# 职责：niri 核心配置（环境/输入/光标/布局/动画/启动项）
# 拆分：binds → niri-binds.nix；窗口/图层规则+输出+毛玻璃 → niri-rules.nix
# ============================================================
{
  config,
  lib,
  my,
  ...
}:

{
  wayland.windowManager.niri = {
    enable = true;

    # package 保留默认（pkgs.niri）：启用构建期 `niri validate` 校验

    settings = {
      # 截图保存位置
      "screenshot-path" = "~/Pictures/Screenshots/Niri-screenshots/%Y-%m-%d %H-%M-%S.png";

      # 环境变量（合成器作用域，喂给 spawn 的应用）
      # STANDARDS §4：IM 变量双作用域，此处 = 合成器层(REF:2026-08-21-fcitx5-gtk)
      environment = {
        LANGUAGE = "zh_CN:en";
        LANG = "zh_CN.UTF-8";
        # 解决漏字问题（副作用：steam 等 X11 应用可能无法用中文输入法）
        LC_CTYPE = "en_US.UTF-8";
        XMODIFIERS = "@im=fcitx";
        # 🔴 现代推荐（fcitx wiki 2025-09 + niri#3099）：Qt6 原生 text-input-v3 优先，fcitx 兜底
        QT_IM_MODULES = "wayland;fcitx";
        QT_IM_MODULE = "fcitx";
        # qt 主题（appearance.nix qt.platformTheme 也设置，这里供 niri spawn 层）
        QT_QPA_PLATFORMTHEME = "gtk3";
        QT_QPA_PLATFORMTHEME_QT6 = "gtk3";
        # 桌面壳图标主题（Noctalia 外壳跟随）：papirus-icon-theme 已装进用户 profile
        QS_ICON_THEME = "Papirus-Dark";
        # 默认文本编辑器
        EDITOR = "vim";
      };

      # 光标（名称/尺寸均引用 HM 选项，单一来源 = home.pointerCursor，见 home/modules/theme/）
      cursor = {
        "xcursor-theme" = config.home.pointerCursor.name;
        "xcursor-size" = config.home.pointerCursor.size; # 尺寸单一来源（原硬编码 30 与 HM 24 打架，统一 30）
        "hide-after-inactive-ms" = 15000; # 闲置 15s 自动隐藏
      };

      # 带缩略图的窗口切换（Mod+Tab 唤出）
      "recent-windows" = {
        "debounce-ms" = 750;
        "open-delay-ms" = 150;
        highlight = {
          # 8 位 hex = 6 位色 + alpha（Mocha 色板引用，my.catppuccin.palette 单一来源）
          "active-color" = "${my.catppuccin.palette.overlay1}ff";
          "urgent-color" = "${my.catppuccin.palette.red}ff";
          padding = 30; # 缩略图背景内间距
          "corner-radius" = 12; # 缩略图背景圆角
        };
        previews = {
          "max-height" = 480;
          "max-scale" = 0.2;
        };
        binds = {
          # scope：当前工作区 / 当前显示器 / 全部窗口
          "Mod+Tab" = {
            "next-window" = {
              _props = {
                scope = "workspace";
              };
            };
          };
          "Mod+Shift+Tab" = {
            "previous-window" = {
              _props = {
                scope = "workspace";
              };
            };
          };
          # grave = 波浪键，显示当前应用的所有窗口
          "Mod+grave" = {
            "next-window" = {
              _props = {
                filter = "app-id";
              };
            };
          };
          "Mod+Shift+grave" = {
            "previous-window" = {
              _props = {
                filter = "app-id";
              };
            };
          };
        };
      };

      # 输入（键盘/触摸板/鼠标）
      input = {
        keyboard = {
          # 留空 = niri 从 org.freedesktop.locale1 取 xkb 设置（localectl 管理）
          xkb = { };
          "repeat-delay" = 250;
          "repeat-rate" = 35;
        };
        touchpad = {
          tap = { };
          "natural-scroll" = { };
        };
        mouse = {
          "accel-speed" = -0.15;
          "accel-profile" = "flat"; # 禁用鼠标加速
        };
        trackpoint = { };
      };

      # overview（工作区总览）
      overview = {
        # 关掉工作区阴影：配合 layout 透明背景，共用 Noctalia 壁纸层（backdrop）
        # 修复：原空块渲染为裸 workspace-shadow = 默认开启，注释意图未生效，此处显式 off
        "workspace-shadow" = {
          off = { };
        };
        zoom = 0.5;
      };

      # 布局（窗口间距/宽度预设/焦点环/边框/阴影）
      layout = {
        # 工作区背景透明 → 透出 Noctalia 壁纸层（经 niri-rules.nix 的 layer-rule 进 backdrop）
        "background-color" = "transparent";
        gaps = 12; # 窗口间距（逻辑像素）
        "center-focused-column" = "never";
        # 预设窗口宽度（Mod+R 循环切换）
        "preset-column-widths" = {
          _children = [
            {
              proportion = 0.33333;
            }
            {
              proportion = 0.5;
            }
            {
              proportion = 0.66667;
            }
          ];
        };
        # 新窗口默认宽度
        "default-column-width" = {
          proportion = 0.5;
        };
        # 聚焦窗口焦点环（配色 = Mocha 色板引用：mauve 聚焦 / surface2 非聚焦 / red 紧急，
        # 单一来源 my.catppuccin.palette，与 GTK/Noctalia 同源）
        "focus-ring" = {
          width = 3;
          "active-color" = my.catppuccin.palette.mauve;
          "inactive-color" = my.catppuccin.palette.surface2;
          "urgent-color" = my.catppuccin.palette.red;
        };
        # 窗口边框（关闭，用 focus-ring；配色键随 palette 走，将来启用即同源）
        border = {
          off = { };
          width = 4;
          "active-color" = my.catppuccin.palette.mauve;
          "inactive-color" = my.catppuccin.palette.surface2;
          "urgent-color" = my.catppuccin.palette.red;
        };
        # 窗口阴影（毛玻璃方案的立体感来源）
        shadow = {
          on = { };
          softness = 20;
          spread = 2;
          offset = {
            _props = {
              x = -4;
              y = -4;
            };
          };
          color = "rgba(0, 0, 0, 0.7)";
        };
        struts = { };
      };

      # 启动项（spawn-at-startup，_children 保证逐条独立节点）
      # 🔴 原 /home/ran 硬编码改为 ${config.home.homeDirectory} 声明式引用（STANDARDS §0.2）
      _children = [
        # 屏幕分享/录屏环境（portal 服务由 xdg-desktop-portal 经 dbus 自动拉起）
        {
          "spawn-sh-at-startup" = [
            "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=niri"
          ];
        }
        # GNOME tracker 修复
        {
          "spawn-sh-at-startup" = [ "systemctl --user set-environment XDG_SESSION_CLASS=user" ];
        }
        # 输入法
        {
          "spawn-at-startup" = [ "fcitx5" ];
        }
        # wayland <--> x11 剪贴板同步
        {
          "spawn-at-startup" = [
            "systemctl"
            "--user"
            "start"
            "linuxqq-clipsync"
          ];
        }
        # 自动护眼（wlsunset 经纬度配置在脚本内；原 ~ 路径 niri 不展开 → 改绝对路径）
        {
          "spawn-at-startup" = [ "${config.home.homeDirectory}/.config/niri/scripts/toggle-wlsunset" ];
        }
        # 明暗主题固定 dark（Noctalia theme.mode=dark + GTK Catppuccin Mocha），无需自动切换脚本
        # 截图音效守护进程
        {
          "spawn-at-startup" = [ "${config.home.homeDirectory}/.config/niri/scripts/screenshot-sound.sh" ];
        }
        # 允许 root 通过用户 xwayland 开窗
        {
          "spawn-at-startup" = [
            "xhost"
            "+si:localuser:root"
          ];
        }

      ];

      # 快捷键教程浮层：跳过启动提示 + 隐藏未绑定 action
      "hotkey-overlay" = {
        "skip-at-startup" = { };
        "hide-not-bound" = { };
      };

      # 隐藏窗口标题栏
      "prefer-no-csd" = { };

      # ---- NVIDIA + Chrome/Electron Wayland 滚动闪烁修复 ----
      # 根因：niri 旧版未实现 linux-drm-syncobj-v1（explicit sync），NVIDIA 隐式同步竞态
      # 🔴 2026-08：驱动 595.91.07 原生支持 explicit sync + niri 新版已实现该协议。
      #    若更新 niri 后未再出现闪烁，可删掉此块用原生显式同步（性能更好）；复现则恢复。
      debug = {
        "wait-for-frame-completion-before-queueing" = { };
      };
    };
  };

  # 启动脚本目录（swayidle/toggle-wlsunset/screenshot-sound 等）
  xdg.configFile."niri/scripts" = {
    source = ../../source/niri/scripts;
    recursive = true;
    force = true; # 覆盖旧版本散落文件
  };

  # 迁移清理（2026-08-28）：删除旧拆分架构遗留的 store symlink
  # 不清除的后果：niri-binds 脚本递归 grep *.kdl 会重复读到旧键位
  # theme-switch：已下线的自定义明暗脚本（明暗现为 Noctalia theme 固定 dark），清残留符号链接
  home.activation.cleanStaleNiriLinks = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    for f in animations.kdl binds.kdl blur.kdl hyprlock-colors.conf hyprlock.conf layout.kdl output.kdl rule.kdl theme-switch; do
      if [ -L "$HOME/.config/niri/$f" ]; then
        $DRY_RUN_CMD rm "$HOME/.config/niri/$f"
      fi
    done
  '';
}
