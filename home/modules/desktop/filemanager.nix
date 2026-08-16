_:

{
  xdg = {
    # ---- 默认应用 (mimeapps) ----
    # 效果：图片→imv、视频→mpv、文本→nvim、目录→nautilus、网页→firefox
    # 未配置 .exe 关联（无需 Windows 程序包装器）
    configFile."mimeapps.list".force = true;
    dataFile."applications/mimeapps.list".force = true;
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
        "image/png" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/webp" = "imv.desktop";
        "image/bmp" = "imv.desktop";
        "image/tiff" = "imv.desktop";
        "video/webm" = "mpv.desktop";
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/avi" = "mpv.desktop";
        "video/quicktime" = "mpv.desktop";
        "application/x-shellscript" = "nvim.desktop";
        "text/plain" = "nvim.desktop";
        "inode/directory" = "org.gnome.Nautilus.desktop";
      };
    };
  };
}
