# ============================================================
# misc.nix —— 桌面杂项（通知/portal/视频/截图标注/默认应用）
# ============================================================
{
  config,
  pkgs,
  lib,
  ...
}:

let
  # 结构化生成器（pkgs.formats）：swaync JSON / xdg-desktop-portal INI
  jsonFormat = pkgs.formats.json { };
  iniFormat = pkgs.formats.ini { };
in
{
  xdg = {
    configFile = {
      # SwayNC 通知（真毛玻璃，niri 26.04 原生支持）
      # config.json 由 pkgs.formats.json 从 attrset 生成
      "swaync/config.json" = {
        source = jsonFormat.generate "swaync-config.json" {
          "$schema" = "/etc/xdg/swaync/configSchema.json";
          positionX = "right";
          positionY = "top";
          layer = "overlay";
          "control-center-layer" = "top";
          "layer-shell" = true;
          "cssPriority" = "user";
          "background-blur" = true;
          timeout = 8;
          "control-center-width" = 480;
          "control-center-height" = 600;
          "notification-window-width" = 480;
          "transition-time" = 200;
          "notification-grouping" = true;
          widgets = [
            "title"
            "dnd"
            "notifications"
          ];
        };
        force = true; # 覆盖 swaync 首次运行自动生成的默认配置
      };
      "swaync/style.css".text = ''
        /* Catppuccin Mocha 毛玻璃通知 */
        /* blur 区域圆角联动自 --border-radius 变量 */
        :root {
          --cc-bg: rgba(30, 30, 46, 0.8);
          --noti-bg: 30, 30, 46;
          --noti-bg-alpha: 0.75;
          --noti-border-color: rgba(203, 166, 247, 0.45);
          --border-radius: 18px;
          --border: 1.5px solid var(--noti-border-color);
          --text-color: #cdd6f4;
          --text-color-disabled: #6c7086;
          --notification-shadow: 0 1px 4px rgba(0, 0, 0, 0.12), 0 8px 24px rgba(0, 0, 0, 0.15);
        }

        .control-center {
          background: var(--cc-bg);
          border-radius: var(--border-radius);
          border: var(--border);
          box-shadow: var(--notification-shadow), inset 0 0 0 1px rgba(255, 255, 255, 0.09);
        }

        .notification {
          border-radius: var(--border-radius);
          border: var(--border);
          background: rgba(var(--noti-bg), var(--noti-bg-alpha));
          box-shadow: var(--notification-shadow), inset 0 0 0 1px rgba(255, 255, 255, 0.1);
          padding: 14px 16px;
        }

        .notification:hover {
          background: rgba(49, 50, 68, 0.55);
        }

        .notification.critical {
          border-color: rgba(243, 139, 168, 0.4);
          background: rgba(60, 30, 40, 0.5);
        }

        .summary {
          color: var(--text-color);
          font-weight: bold;
        }
        .body {
          color: var(--text-color);
        }

        .widget-title > label {
          color: var(--text-color);
          font-weight: bold;
        }
        .widget-dnd > switch {
          color: #cba6f7;
        }

        /* 留白：通知窗口边缘 + 卡片间距 */
        .floating-notifications {
          margin: 12px;
        }
        .control-center .notification {
          margin-bottom: 10px;
        }
        .control-center .notification-group-header {
          margin: 4px 0 8px;
        }
      '';

    };

    # ---- 用户目录 ----
    # 统一英文名（2026-08-29）：原 ~/下载 与 ~/Documents/Downloads/Pictures 并存导致混乱
    userDirs = {
      enable = true;
      createDirectories = true; # 缺失目录自动创建
      # 🔴 消除弃用警告：stateVersion < 26.05 时显式声明保持旧行为(REF:2026-08-30-userdirs-warning)
      setSessionVariables = true;
      desktop = "Desktop";
      documents = "Documents";
      download = "Downloads";
      music = "Music";
      pictures = "Pictures";
      publicShare = "Public";
      templates = "Templates";
      videos = "Videos";
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        # 浏览器（chrome 为默认）
        "text/html" = "chrome.desktop";
        "application/xhtml+xml" = "chrome.desktop";
        "x-scheme-handler/http" = "chrome.desktop";
        "x-scheme-handler/https" = "chrome.desktop";
        "x-scheme-handler/about" = "chrome.desktop";
        "x-scheme-handler/unknown" = "chrome.desktop";
        # 图片
        "image/png" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/webp" = "imv.desktop";
        "image/bmp" = "imv.desktop";
        "image/tiff" = "imv.desktop";
        # 视频
        "video/webm" = "mpv.desktop";
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/avi" = "mpv.desktop";
        "video/quicktime" = "mpv.desktop";
        # 文本
        "application/x-shellscript" = "nvim.desktop";
        "text/plain" = "nvim.desktop";
        # 目录
        "inode/directory" = "org.gnome.Nautilus.desktop";
      };
    };
  };

  # xdg-desktop-portal（截屏/录屏走 gnome portal、文件选择器用 gtk）
  xdg.configFile."xdg-desktop-portal/niri-portals.conf" = {
    source = iniFormat.generate "niri-portals.conf" {
      preferred = {
        default = "gnome;gtk;";
        "org.freedesktop.impl.portal.Access" = "gtk;";
        "org.freedesktop.impl.portal.Notification" = "gtk;";
        "org.freedesktop.impl.portal.FileChooser" = "gtk;";
        "org.freedesktop.impl.portal.Secret" = "gnome-keyring;";
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        "org.freedesktop.impl.portal.Screenshot" = "gnome";
      };
    };
  };

  # 迁移清理（2026-08-28）：删除旧 xdg.configFile "mpv/config"
  # 旧条目不再被读取，GC 后为悬空链接(REF:2026-08-28-mpv-cleanup)
  home.activation.cleanStaleMpvConfig = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/mpv/config" ]; then
      $DRY_RUN_CMD rm "$HOME/.config/mpv/config"
    fi
  '';

  # mpv（Vulkan 渲染 + auto-safe 硬解）
  programs.mpv = {
    enable = true;
    config = {
      "gpu-api" = "vulkan"; # Vulkan 渲染后端
      hwdec = "auto-safe"; # 通用自动模式硬解
    };
  };

  # satty 截图标注（默认画笔、右键直接保存到剪贴板、缩放 1.1）
  # 2026-08-29 起模块自装 satty 二进制（package 默认），系统层不再安装
  programs.satty = {
    enable = true;
    settings = {
      general = {
        "copy-command" = "wl-copy";
        "focus-toggles-toolbars" = true;
        "initial-tool" = "brush";
        "zoom-factor" = 1.1;
        "actions-on-right-click" = [ "save-to-clipboard" ];
      };
      font = {
        family = "Noto Sans CJK SC";
        style = "Regular";
        fallback = [
          "Noto Sans CJK SC"
          "Noto Sans CJK JP"
          "Noto Sans CJK TC"
          "Noto Sans CJK KR"
        ];
      };
    };
  };
}
