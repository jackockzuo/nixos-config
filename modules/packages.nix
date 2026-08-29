# ============================================================
# packages.nix —— 系统级全局二进制 + 系统字体（曾独立 fonts.nix，并入）
# 职责：需要 root/全局 PATH 的二进制（按用途分节）+ fonts.packages
# 修改：装/卸全局包 → 改对应分节，宁删注释不混堆
# 原则：用户级工具/应用放 home-manager，这里只留系统必需
# 🔴 2026-08-29 瘦身：纯 GUI 用户应用（firefox/chrome/nautilus/imv/localsend/
#    btrfs-assistant/mpv/satty）已下放用户层（niri 会话 PATH 含 ~/.nix-profile/bin），
#    系统层只留登录 shell / root 服务 / niri spawn 依赖 / 系统工具。
# 关联：home-manager/desktop/appearance.nix（fontconfig 渲染规则）
# ============================================================
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ---- 登录 shell（users.nix 指定，必须在系统包）----
    fish # 🔴 登录 shell（users.users.ran.shell = pkgs.fish），必须在系统包中

    # ---- X11/Wayland 兼容层 ----
    xwayland-satellite # niri 26.04 经 xwayland-satellite 提供 X11 应用支持
    xhost # 允许 root 经用户 xwayland 开窗（niri spawn-at-startup 调用）

    # ---- 认证/电源/护眼 ----
    polkit_gnome # 认证代理（niri spawn-at-startup）
    wlsunset # 护眼（niri 脚本依赖）
    swayidle # 闲置锁屏（niri 脚本依赖）
    sound-theme-freedesktop # 系统音效主题（screenshot-sound.sh 的 camera-shutter.oga 依赖）

    # ---- 容器与虚拟化 ----
    distrobox # 容器工作流（依赖 rootless podman）
    podman # 容器运行时
    fuse-overlayfs # 可选，提升容器内 FUSE 性能
    appimage-run # AppImage 运行器

    # ---- 联网工具（迁移后第一件事：查资料）----
    # firefox / google-chrome 已下放用户层（desktop/default.nix home.packages）
    wget
    git
    curl

    # ---- 网络诊断 ----
    dnsutils
    traceroute
    openssh

    # ---- 桌面必需二进制（NixOS 系统层安装，HM 只管配置）----
    # 🔴 2026-08-29：grim/slurp/wl-clipboard/kitty/mpv 等已随 GUI 下放或由 programs 模块自装，
    #    系统层只留 niri spawn 直接依赖（swaync/brightnessctl/playerctl）与锁屏（hyprlock）
    kitty
    hyprlock

    # ---- 通知/截图标注/亮度（niri spawn + HM 配置引用）----
    swaynotificationcenter # swaync（niri spawn-at-startup）
    brightnessctl # 亮度调节（niri 绑定）
    playerctl # 全局媒体控制（可绑定 niri 多媒体键：暂停/下一首）

    # ---- 文件管理（mimeapps 默认应用）----
    # nautilus / imv 已下放用户层

    # ---- 工具脚本与右键动作依赖 ----
    libnotify # notify-send
    python3
    mediainfo

    # ---- 系统工具 ----
    btrfs-progs
    # btrfs-assistant（GUI）已下放用户层
    vim

    # ---- 同步工具 ----
    # localsend（GUI）已下放用户层

    # ---- 音频调试工具 ----
    pulseaudio # 虽然禁用了服务端，但我们需要它提供的 `pactl` 命令行工具
    alsa-utils # 提供 `alsamixer` 和 `amixer`，用于底层调试
  ];

  # ============ 系统字体（曾独立 fonts.nix，并入）============
  fonts.packages = with pkgs; [
    maple-mono.NF-CN # "Maple Mono NF CN"（仅终端 kitty 使用）
    nerd-fonts.jetbrains-mono # 浏览器/等宽代码块（fontconfig monospace 首选）
    noto-fonts-cjk-sans # 中文默认（浏览器/UI/输入法候选框）
    noto-fonts
    inter # DMS UI 字体（Inter Variable，桌面壳运行时使用）
    fira-code # DMS 等宽字体（Fira Code，桌面壳 mono 使用）
  ];
}
