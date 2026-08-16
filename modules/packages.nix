# ============================================================
# packages.nix —— 系统级全局二进制
# 职责：需要 root/全局 PATH 的二进制（按用途分节）
# 修改：装/卸全局包 → 改对应分节，宁删注释不混堆
# 原则：用户级工具/应用放 home-manager，这里只留系统必需
# ============================================================
{ pkgs, ... }:

let
  # Firefox 单独走 Wayland text-input 协议
  # 🔴 原因：Firefox 原生 Wayland 运行（MOZ_ENABLE_WAYLAND=1），全局 GTK_IM_MODULE=fcitx
  #    会强制它额外加载 fcitx5-gtk 的 dbus 通道 → 双通道冲突 → 候选框（皮肤）不显示。
  #    见 fcitx5 官方 FAQ：Wayland 原生 GTK 应用应走 text-input 协议。
  #    这里只对 firefox 覆盖为 wayland，XWayland 应用（QQ 等）仍用全局 fcitx。
  firefox = pkgs.symlinkJoin {
    name = "firefox-wayland-im";
    paths = [ pkgs.firefox ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/firefox \
        --set GTK_IM_MODULE wayland
    '';
  };
in

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

    # ---- 容器与虚拟化 ----
    distrobox # 容器工作流（依赖 rootless podman）
    podman # 容器运行时
    fuse-overlayfs # 可选，提升容器内 FUSE 性能
    appimage-run # AppImage 运行器

    # ---- 联网工具（迁移后第一件事：查资料）----
    firefox
    google-chrome
    wget
    git
    curl

    # ---- 网络诊断 ----
    dnsutils
    traceroute
    openssh

    # ---- 桌面必需二进制（NixOS 系统层安装，HM 只管配置）----
    kitty
    hyprlock
    grim # 截图（niri 绑定调用）
    slurp # 区域选择
    wl-clipboard
    mpv

    # ---- 通知/截图标注/亮度（niri spawn + HM 配置引用）----
    swaynotificationcenter # swaync（niri spawn-at-startup）
    satty # 截图标注（niri 绑定调用）
    brightnessctl # 亮度调节（niri 绑定）
    playerctl # 全局媒体控制（可绑定 niri 多媒体键：暂停/下一首）

    # ---- 文件管理（mimeapps 默认应用）----
    nautilus
    imv

    # ---- 工具脚本与右键动作依赖 ----
    libnotify # notify-send
    python3
    mediainfo

    # ---- 系统工具 ----
    btrfs-progs
    btrfs-assistant # snapper 快照 GUI 管理（rule.kdl 已有其浮动窗口规则）
    vim

    # ---- 同步工具 ----
    localsend
  ];
}
