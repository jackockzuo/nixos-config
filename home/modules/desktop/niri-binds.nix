# ============================================================
# niri-binds.nix —— 合成器快捷键（原 binds.kdl）
# 所有绑定均带 hotkey-overlay-title，按 Mod+F1 可查看全部
# ============================================================
_:

{
  wayland.windowManager.niri.settings.binds = {
    # 📖 快捷键说明书（Mod+F1 唤出）
    "Mod+F1" = {
      "show-hotkey-overlay" = { };
    };

    # 🔌 电源菜单（DMS 原生电源菜单）
    "Mod+X" = {
      _props = {
        "hotkey-overlay-title" = "电源菜单 (关机/重启/锁屏/注销)";
      };
      spawn = [
        "dms"
        "ipc"
        "call"
        "powermenu"
        "toggle"
      ];
    };
    "Mod+Escape" = {
      _props = {
        "hotkey-overlay-title" = "电源菜单 (关机/重启/锁屏/注销)";
      };
      spawn = [
        "dms"
        "ipc"
        "call"
        "powermenu"
        "toggle"
      ];
    };

    # 🚀 启动常用程序
    "Mod+P" = {
      _props = {
        "hotkey-overlay-title" = "启动器：搜索并打开应用 (DMS Spotlight)";
      };
      spawn = [
        "dms"
        "ipc"
        "call"
        "spotlight"
        "toggle"
      ];
    };
    "Mod+T" = {
      _props = {
        "hotkey-overlay-title" = "打开终端 (Kitty)";
      };
      spawn = [ "kitty" ];
    };
    "Mod+B" = {
      _props = {
        "hotkey-overlay-title" = "打开默认浏览器 (Baidu)";
      };
      spawn = [
        "xdg-open"
        "https://www.baidu.com"
      ];
    };
    "Mod+E" = {
      _props = {
        "hotkey-overlay-title" = "打开文件管理器 (Nautilus)";
      };
      spawn = [ "nautilus" ];
    };

    # 🎮 游戏化窗口焦点切换（WASD）
    "Mod+W" = {
      _props = {
        "hotkey-overlay-title" = "聚焦：上方的窗口";
      };
      "focus-window-up" = { };
    };
    "Mod+A" = {
      _props = {
        "hotkey-overlay-title" = "聚焦：左侧的窗口";
      };
      "focus-column-left" = { };
    };
    "Mod+S" = {
      _props = {
        "hotkey-overlay-title" = "聚焦：下方的窗口";
      };
      "focus-window-down" = { };
    };
    "Mod+D" = {
      _props = {
        "hotkey-overlay-title" = "聚焦：右侧的窗口";
      };
      "focus-column-right" = { };
    };

    # 📦 移动窗口位置（Ctrl + WASD）
    "Mod+Ctrl+W" = {
      _props = {
        "hotkey-overlay-title" = "移动窗口：向上";
      };
      "move-window-up" = { };
    };
    "Mod+Ctrl+A" = {
      _props = {
        "hotkey-overlay-title" = "移动窗口：向左";
      };
      "move-column-left" = { };
    };
    "Mod+Ctrl+S" = {
      _props = {
        "hotkey-overlay-title" = "移动窗口：向下";
      };
      "move-window-down" = { };
    };
    "Mod+Ctrl+D" = {
      _props = {
        "hotkey-overlay-title" = "移动窗口：向右";
      };
      "move-column-right" = { };
    };

    # 📐 窗口状态与尺寸控制
    "Mod+Q" = {
      _props = {
        "hotkey-overlay-title" = "关闭当前选中的窗口";
      };
      "close-window" = { };
    };
    "Mod+F" = {
      _props = {
        "hotkey-overlay-title" = "最大化当前窗口 (填充空白)";
      };
      "maximize-column" = { };
    };
    "Mod+Alt+F" = {
      _props = {
        "hotkey-overlay-title" = "切换全屏窗口";
      };
      "fullscreen-window" = { };
    };
    "Mod+V" = {
      _props = {
        "hotkey-overlay-title" = "切换窗口模式 (浮动/平铺)";
      };
      "toggle-window-floating" = { };
    };
    "Mod+R" = {
      _props = {
        "hotkey-overlay-title" = "调整窗口宽度 (按预设循环切换)";
      };
      "switch-preset-column-width" = { };
    };

    # 🖱️ 鼠标滚轮切换工作区（按住 Mod + 滚动）
    "Mod+WheelScrollDown" = {
      _props = {
        "cooldown-ms" = 150;
        "hotkey-overlay-title" = "切换工作区：向下滚动";
      };
      "focus-workspace-down" = { };
    };
    "Mod+WheelScrollUp" = {
      _props = {
        "cooldown-ms" = 150;
        "hotkey-overlay-title" = "切换工作区：向上滚动";
      };
      "focus-workspace-up" = { };
    };

    # 备用：单手数字键 1-5 切换工作区
    "Mod+1" = {
      _props = {
        "hotkey-overlay-title" = "切换到工作区 1";
      };
      "focus-workspace" = 1;
    };
    "Mod+2" = {
      _props = {
        "hotkey-overlay-title" = "切换到工作区 2";
      };
      "focus-workspace" = 2;
    };
    "Mod+3" = {
      _props = {
        "hotkey-overlay-title" = "切换到工作区 3";
      };
      "focus-workspace" = 3;
    };
    "Mod+4" = {
      _props = {
        "hotkey-overlay-title" = "切换到工作区 4";
      };
      "focus-workspace" = 4;
    };
    "Mod+5" = {
      _props = {
        "hotkey-overlay-title" = "切换到工作区 5";
      };
      "focus-workspace" = 5;
    };

    # 移动窗口到工作区 1-5
    "Mod+Ctrl+1" = {
      _props = {
        "hotkey-overlay-title" = "移动窗口到工作区 1";
      };
      "move-column-to-workspace" = 1;
    };
    "Mod+Ctrl+2" = {
      _props = {
        "hotkey-overlay-title" = "移动窗口到工作区 2";
      };
      "move-column-to-workspace" = 2;
    };
    "Mod+Ctrl+3" = {
      _props = {
        "hotkey-overlay-title" = "移动窗口到工作区 3";
      };
      "move-column-to-workspace" = 3;
    };
    "Mod+Ctrl+4" = {
      _props = {
        "hotkey-overlay-title" = "移动窗口到工作区 4";
      };
      "move-column-to-workspace" = 4;
    };
    "Mod+Ctrl+5" = {
      _props = {
        "hotkey-overlay-title" = "移动窗口到工作区 5";
      };
      "move-column-to-workspace" = 5;
    };

    # 📸 截图与剪贴板
    "Mod+Shift+S" = {
      _props = {
        "hotkey-overlay-title" = "屏幕截图：按下后用鼠标拖拽框选";
      };
      spawn = [
        "niri"
        "msg"
        "action"
        "screenshot"
      ];
    };
    "Mod+Shift+V" = {
      _props = {
        "hotkey-overlay-title" = "剪贴板历史 (DMS Clipboard)";
      };
      spawn = [
        "dms"
        "ipc"
        "call"
        "clipboard"
        "toggle"
      ];
    };

    # 🔊 声音与亮度（键盘自带的多媒体键，锁屏可用）
    "XF86AudioRaiseVolume" = {
      _props = {
        "allow-when-locked" = true;
        "hotkey-overlay-title" = "音量增大";
      };
      spawn = [
        "wpctl"
        "set-volume"
        "@DEFAULT_AUDIO_SINK@"
        "5%+"
      ];
    };
    "XF86AudioLowerVolume" = {
      _props = {
        "allow-when-locked" = true;
        "hotkey-overlay-title" = "音量减小";
      };
      spawn = [
        "wpctl"
        "set-volume"
        "@DEFAULT_AUDIO_SINK@"
        "5%-"
      ];
    };
    "XF86AudioMute" = {
      _props = {
        "allow-when-locked" = true;
        "hotkey-overlay-title" = "静音切换";
      };
      spawn = [
        "wpctl"
        "set-mute"
        "@DEFAULT_AUDIO_SINK@"
        "toggle"
      ];
    };
    "XF86MonBrightnessUp" = {
      _props = {
        "allow-when-locked" = true;
        "hotkey-overlay-title" = "亮度增加";
      };
      spawn = [
        "brightnessctl"
        "set"
        "+5%"
      ];
    };
    "XF86MonBrightnessDown" = {
      _props = {
        "allow-when-locked" = true;
        "hotkey-overlay-title" = "亮度降低";
      };
      spawn = [
        "brightnessctl"
        "set"
        "5%-"
      ];
    };
  };
}
