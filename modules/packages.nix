# ============================================================
# packages.nix —— 系统级全局二进制 + 系统字体
# 职责：需要 root/全局 PATH 的二进制（按用途分节）+ fonts.packages
# 原则：用户级工具/应用放 home-manager，这里只留系统必需
# ============================================================
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ---- 登录 shell（必须在系统包）----
    fish

    # ---- X11/Wayland 兼容层 ----
    xwayland-satellite # niri 26.04 经 xwayland-satellite 提供 X11 应用支持
    xhost # niri spawn-at-startup 调用

    # ---- 认证/电源/护眼 ----
    polkit_gnome # 认证代理（niri spawn-at-startup）
    wlsunset # 护眼（niri 脚本依赖）
    swayidle # 闲置锁屏（niri 脚本依赖）
    sound-theme-freedesktop # 系统音效主题

    # ---- 容器与虚拟化 ----
    distrobox
    podman
    fuse-overlayfs
    appimage-run

    # ---- 联网工具 ----
    wget
    git
    curl

    # ---- 网络诊断 ----
    dnsutils
    traceroute
    openssh

    # ---- 桌面必需二进制（niri spawn 直接依赖）----
    kitty
    hyprlock
    swaynotificationcenter # swaync（niri spawn-at-startup）
    brightnessctl # 亮度调节（niri 绑定）
    playerctl # 全局媒体控制

    # ---- 工具脚本依赖 ----
    libnotify # notify-send
    python3
    mediainfo

    # ---- 系统工具 ----
    btrfs-progs
    vim

    # ---- 音频调试工具 ----
    pulseaudio # 提供 pactl 命令行工具
    alsa-utils # 提供 alsamixer/amixer

    pkgs.dae
  ];

  # 系统字体
  fonts.packages = with pkgs; [
    maple-mono.NF-CN # 终端 kitty 使用
    nerd-fonts.jetbrains-mono # 浏览器/等宽代码块
    noto-fonts-cjk-sans # 中文默认
    noto-fonts
    inter # DMS UI 字体
    fira-code # DMS 等宽字体
  ];
}
