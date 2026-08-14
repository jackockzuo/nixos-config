# NixOS 系统配置 - HP OMEN 16-wf0xxx (ran)
# 原则：最小系统（驱动 + 桌面基础 + 服务），应用之后由用户自行重装
{ config, pkgs, ... }:

{
  system.stateVersion = "25.05";

  # 允许 unfree（nvidia 驱动、chrome 等）
  nixpkgs.config.allowUnfree = true;

  # ============ 主机与网络 ============
  networking.hostName = "omen";
  networking.networkmanager.enable = true;

  # ============ 用户 ============
  users.users.ran = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    # 临时初始密码：登录后立即 `passwd` 修改，然后删掉这行再 rebuild
    initialPassword = "ran";
  };
  users.mutableUsers = false;

  # ============ 引导：GRUB + 保留 Windows 双系统 ============
  boot.loader = {
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
    grub = {
      enable = true;
      device = "nodev";          # EFI 模式
      efiSupport = true;
      useOSProber = true;        # 自动检测 Windows
    };
  };

  # ============ 内核：最新（≈ 现在的 7.1.x）============
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "ibt=off"                    # nvidia 兼容（和 Arch 时一致）
    "nvidia-drm.modeset=1"
  ];

  # ============ NVIDIA RTX 4060（open 驱动，package 自动匹配）============
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaPersistenced = true;
    prime = {
      # 混合显卡：默认 offload（按需调用独显）
      offload.enable = true;
      # sync.enable = true;      # 若内屏直连独显，改用这行并注释掉 offload
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # ============ 交换：zram（和 Arch 时一致）============
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;

  # ============ 音频 ============
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ============ 输入法：fcitx5（系统级，比 Arch 上更顺）============
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-rime
      rime-ice
      catppuccin-fcitx5
      fcitx5-gtk
      qt6Packages.fcitx5-chinese-addons
    ];
  };

  # ============ 桌面：greetd 直接拉起 niri 会话（配置由 HM 提供）============
  # 说明：默认会话直接以 ran 启动 niri（免登录）；想要登录界面时改 command 为 tuigreet
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.niri}/bin/niri-session";
      user = "ran";
    };
  };

  # ============ 基础服务 ============
  services.udisks2.enable = true;      # U 盘自动挂载（udiskie）
  services.gvfs.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;                 # niri 屏幕共享/portal
  };
  programs.fuse.userAllowOther = true; # 肥猫云 AppImage 需要

  # ============ 基础工具（应用用户自行重装）============
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    btrfs-progs
    # 联网必需（迁移后第一件事：查资料）
    firefox
    chromium
    wget
    # 网络诊断
    dnsutils
    traceroute
    openssh
    # 桌面必需二进制（NixOS 无 pacman，HM 只管配置，二进制这里补）
    kitty
    hyprlock
    grim
    slurp
    wl-clipboard
    mpv
  ];

  # ============ Nix：国内镜像 + daemon 调优 ============
  nix.settings = {
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    trusted-users = [ "root" "@wheel" ];
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  # 系统级自动 GC（保留 14 天）
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
