# ============================================================
# misc.nix —— 桌面杂项（portal/视频/截图标注/默认应用）
# 2026-09-26 DMS→Noctalia 迁移：SwayNC 通知整块移除（Noctalia 内置通知中心接管）
# ============================================================
{
  pkgs,
  lib,
  ...
}:

let
  # 结构化生成器（pkgs.formats）：xdg-desktop-portal INI
  iniFormat = pkgs.formats.ini { };
in
{
  xdg = {
    # ---- 用户目录 ----
    # 统一英文名（2026-08-29）：原 ~/下载 与 ~/Documents/Downloads/Pictures 并存导致混乱
    userDirs = {
      enable = true;
      createDirectories = true; # 缺失目录自动创建
      # 🔴 消除弃用警告：stateVersion < 26.05 时显式声明保持旧行为
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
        "inode/directory" = "org.kde.dolphin.desktop";
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
  # 旧条目不再被读取，GC 后为悬空链接
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
        # 标注文字用中文 UI 字体（与全局 fontconfig 一致，family 见 modules/packages.nix lxgw-neoxihei）
        family = "LXGW Neo XiHei";
        style = "Regular";
        fallback = [
          "LXGW Neo XiHei"
          "Noto Sans CJK SC"
          "Noto Sans CJK JP"
          "Noto Sans CJK TC"
          "Noto Sans CJK KR"
        ];
      };
    };
  };
}
