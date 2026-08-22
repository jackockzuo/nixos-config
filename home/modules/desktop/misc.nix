# ============================================================
# misc.nix —— 桌面杂项（曾独立 swaync/portal/mpv/screenshot/filemanager，
# 5 个 <60 行小文件按架构量化规则 §2.6 合并）
# 职责：通知(swaync)/portal/视频(mpv)/截图标注(satty)/默认应用(mimeapps)
# ============================================================
_:

{
  xdg = {
    configFile = {
      # ---- SwayNC 通知（真毛玻璃，ext-background-effect-v1，niri 26.04 原生支持）----
      # 二进制 swaynotificationcenter 由系统层安装（NixOS 版含 background-blur 支持）
      "swaync/config.json".text = ''
        {
          "$schema": "/etc/xdg/swaync/configSchema.json",
          "positionX": "right",
          "positionY": "top",
          "layer": "overlay",
          "control-center-layer": "top",
          "layer-shell": true,
          "cssPriority": "user",
          "background-blur": true,
          "timeout": 8,
          "control-center-width": 480,
          "control-center-height": 600,
          "notification-window-width": 480,
          "transition-time": 200,
          "notification-grouping": true,
          "widgets": ["title", "dnd", "notifications"]
        }
      '';
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

      # ---- mpv（Vulkan 渲染 + auto-safe 硬解）----
      "mpv/config".text = ''
        # 使用 vulkan 后端
        gpu-api=vulkan
        # 通用自动模式硬解
        hwdec=auto-safe
      '';

      # ---- satty 截图标注 ----
      # 默认画笔、右键直接保存到剪贴板、缩放 1.1、Noto Sans CJK SC + 中文回退字体
      "satty/config.toml" = {
        source = ../../source/beautify/satty/config.toml;
        force = true; # 覆盖原作者旧配置
      };

      # ---- mimeapps 默认应用（原 filemanager.nix）----
      # 图片→imv、视频→mpv、文本→nvim、目录→nautilus、网页→firefox
      # mimeApps 会自动生成 ~/.config/mimeapps.list 与
      # ~/.local/share/applications/mimeapps.list（无需手动 force）
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        # 浏览器（Firefox 为默认）
        "text/html" = "firefox.desktop";
        "application/xhtml+xml" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
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

  # ---- xdg-desktop-portal（原 portal.nix）----
  # 截屏/录屏走 gnome portal、文件选择器用 gtk（修复屏幕分享/录屏）
  xdg.configFile."xdg-desktop-portal/niri-portals.conf".text = ''
    [preferred]
    default=gnome;gtk;
    org.freedesktop.impl.portal.Access=gtk;
    org.freedesktop.impl.portal.Notification=gtk;
    org.freedesktop.impl.portal.FileChooser=gtk;
    org.freedesktop.impl.portal.Secret=gnome-keyring;
    org.freedesktop.impl.portal.ScreenCast=gnome
    org.freedesktop.impl.portal.Screenshot=gnome
  '';
}
