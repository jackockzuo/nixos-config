# ============================================================
# desktop/packages.nix —— 用户 GUI 应用 + 桌面会话 CLI（纯安装，无配置）
# 落点原则（STANDARDS §3.1）：
#   有官方 HM 模块的走 programs.<x>（此处不列）；纯安装进 home.packages。
#   GUI 应用与桌面会话工具在本文件；通用终端 CLI 在 tools/shell-utils.nix；
#   程序专属依赖随其程序文件（如 yazi.nix）。
# ============================================================
{ pkgs, ... }:

{
  # QQ 原生 Wayland（ozone-platform=wayland）
  xdg.configFile."qq-flags.conf" = {
    force = true; # 覆盖原作者旧配置
    text = ''
      --ozone-platform=wayland
    '';
  };

  home.packages = with pkgs; [
    # ---- 浏览器 ----
    firefox
    google-chrome

    # ---- 图形/媒体应用 ----
    imv # 图片查看
    zed-editor
    opencode
    pi-coding-agent
    wpsoffice-cn
    zotero
    obsidian
    qq
    wechat

    # ---- KDE 图形应用 ----
    kdePackages.dolphin
    kdePackages.dolphin-plugins # 提供 Git 集成等右键服务
    kdePackages.ark # 解压缩，Dolphin 内置支持
    kdePackages.ffmpegthumbs # 视频缩略图
    kdePackages.kimageformats # WebP/HEIF 等缩略图
    kdePackages.okular # PDF 阅读

    # ---- 桌面会话 CLI（niri spawn/绑定依赖，走用户会话 PATH）----
    grim # 截图
    slurp # 区域选择
    wl-clipboard # 剪贴板
    cliphist # 历史剪贴板
    swaynotificationcenter # swaync（niri spawn-at-startup）
    brightnessctl # 亮度调节（niri 绑定）
    playerctl # 全局媒体控制
    wlsunset # 护眼（niri 脚本依赖）
    swayidle # 闲置锁屏（niri 脚本依赖）
    libnotify # notify-send（niri 脚本依赖）
    udiskie # U盘自动挂载

    # ---- 局域网传输 ----
    localsend
  ];
}
