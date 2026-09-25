# ============================================================
# packages.nix —— 系统级全局二进制 + 系统字体
# 职责：需要 root / tty 兜底 / 常驻服务 / 全局 PATH 的二进制（按用途分节）+ fonts.packages
# 原则（STANDARDS §3.1）：仅用户会话使用的 GUI/CLI 一律 home-manager；
#   新增前先问「root 或系统服务需要它在 /run/current-system/sw/bin 吗？」
# ============================================================
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ---- X11/Wayland 兼容层 ----
    xwayland-satellite # niri 26.04 经 xwayland-satellite 提供 X11 应用支持
    xhost # niri spawn-at-startup 调用（允许 root 经用户 xwayland 开窗）

    # ---- 会话/认证组件（greeter 与所有会话统一；先于用户 profile 可用）----
    polkit_gnome # 认证代理（niri spawn-at-startup，走系统 PATH 保证会话内必有）
    sound-theme-freedesktop # 系统音效主题

    # ---- 容器与虚拟化（podman 为系统服务；AppImage 走 binfmt）----
    podman
    fuse-overlayfs
    appimage-run

    # ---- 基线 CLI / 系统排障（root 与 tty 兜底；服务脚本按 /run/current-system/sw/bin 取）----
    wget
    git
    curl
    dnsutils
    traceroute
    openssh

    # ---- 系统工具 ----
    btrfs-progs
    vim # EDITOR 兜底 + root 救援
    cups-pk-helper
    tlp
    tlp-pd

    # ---- 音频调试工具（系统层 pipewire 配套）----
    pulseaudio # 提供 pactl 命令行工具
    alsa-utils # 提供 alsamixer/amixer

    # ---- 系统性能 / 压测 / 调优（多需 root：硬件计数器、调频、块设备 I/O）----
    stress-ng # 全方位压力测试（CPU/内存/I/O/磁盘）
    config.boot.kernelPackages.cpupower # CPU 调频/Governor；跟随 modules/boot.nix 的 kernelProfile 唯一来源
    perf # 内核性能分析（硬件计数器/缓存未命中/分支预测）
    numactl # NUMA 内存/CPU 节点绑定（numactl/numastat）
    fio # 存储 I/O 压测（IOPS/吞吐/延迟）
    iotop # 按进程实时 I/O（类 top）
    nmon # 系统性能全景监控（CPU/内存/网络/磁盘一屏）
    sysstat # iostat/sar/mpstat/pidstat
    iperf3 # 网络吞吐/丢包测试

    # ---- 脚本运行时 ----
    python3
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
