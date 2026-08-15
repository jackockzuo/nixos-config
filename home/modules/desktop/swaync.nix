{ ... }:

{
  # ---- 4. SwayNC 通知（真毛玻璃，ext-background-effect-v1，niri 26.04 原生支持）----
  # 效果：圆角 + 合成器级毛玻璃 + mauve 光晕边框 + 阴影
  # 二进制 swaynotificationcenter 由系统层安装（NixOS 版含 background-blur 支持）
  xdg.configFile."swaync/config.json".text = ''
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
  xdg.configFile."swaync/style.css".text = ''
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

    .notification:hover { background: rgba(49, 50, 68, 0.55); }

    .notification.critical {
      border-color: rgba(243, 139, 168, 0.4);
      background: rgba(60, 30, 40, 0.5);
    }

    .summary { color: var(--text-color); font-weight: bold; }
    .body { color: var(--text-color); }

    .widget-title > label { color: var(--text-color); font-weight: bold; }
    .widget-dnd > switch { color: #cba6f7; }

    /* 留白：通知窗口边缘 + 卡片间距 */
    .floating-notifications { margin: 12px; }
    .control-center .notification { margin-bottom: 10px; }
    .control-center .notification-group-header { margin: 4px 0 8px; }
  '';

}
