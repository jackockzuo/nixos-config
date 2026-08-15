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
    # input: DMS evdev 手势需要；podman: distrobox 容器
    extraGroups = [
      "wheel"
      "networkmanager"
      "podman"
      "input"
    ];
    # 临时初始密码：登录后立即 `passwd` 修改，然后删掉这行再 rebuild
    initialPassword = "ran";
  };
  users.users.root.initialPassword = "rootpassword";
  users.mutableUsers = false;
  # GitHub access token（提升 api.github.com 速率限制；注意：仓库若是 public 切勿提交此 token）
  # nixpkgs 26.11 的 nix.settings.access-tokens 类型为字符串（空格分隔多组 "host=token"）
  nix.settings.access-tokens = "github=***REMOVED***";
  # ============ 引导：GRUB（实际引导链是 GRUB，从 Arch 时代继承）============
  # 🔴 实际排查：固件从 /boot/EFI/NixOS-boot/grubx64.efi (GRUB) 引导，加载 /boot/grub/grub.cfg。
  # NixOS 的 systemd-boot 条目从不被使用 → 每次 switch 只更新 systemd-boot 条目，
  # GRUB 菜单仍指向旧代 → 重启后加载旧系统。
  # 改为 NixOS 管理 GRUB：switch 时自动更新 grub.cfg 指向最新代。
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";        # EFI 模式
      efiSupport = true;
      efiInstallAsRemovable = true;  # 安装为 removable 路径，确保固件能找到
      # 🔴 跨盘发现 Windows：Windows 在另一块盘 (nvme1n1)，os-prober 扫描所有磁盘
      # 的 EFI 系统分区，在 GRUB 菜单添加 Windows Boot Manager 条目
      useOSProber = true;
    };
  };

  # ============ 内核：最新（≈ 现在的 7.1.x）============
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "ibt=off" # nvidia 兼容（KVM 直通/嵌套虚拟化需要）
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

  # ============ 交换：zram ============
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;

  # ============ 音频 ============
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ============ 输入法：fcitx5（系统级）============
  # 注意：.enable/.type 是新式写法（旧 .enabled 已弃用）
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      # 🔴 必须 override fcitx5-rime 的 rimeDataPkgs 加入 rime-ice！
      # nixpkgs 默认 rimeDataPkgs 只有 [ rime-data ]（基础包，不含 rime_ice schema），
      # 导致 fcitx5-rime 的共享数据目录 share/rime-data 里没有 rime_ice.schema.yaml，
      # rime 引擎启动部署时报 "missing input schema: rime_ice" → 输入法失效。
      # 之前 HM 用 xdg.dataFile 往用户目录塞 symlink 是错误方案：
      # rime 的 SyncUserData 部署任务会把共享目录里不存在的文件从用户目录删除。
      (fcitx5-rime.override {
        rimeDataPkgs = [
          pkgs.rime-data
          pkgs.rime-ice
        ];
      })
      rime-ice
      catppuccin-fcitx5
      fcitx5-gtk
      qt6Packages.fcitx5-chinese-addons
    ];
  };
  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    # 这一条是 Kitty 专属的关键变量，缺少它 Kitty 一定无法激活输入法
    GLFW_IM_MODULE = "fcitx";
  };

  # ============ 桌面：greetd + DMS Greeter 登录界面 ============
  # 说明：DMS greeter 模块（dms.nixosModules.greeter）会接管 default_session.command，
  # 启动 DMS 登录界面；登录后由 greeter 内部拉起 niri 会话。
  # 🔴 注意：这里不能显式设置 command！greeter 模块用 lib.mkDefault 设置 command，
  # 显式赋值优先级更高会覆盖掉 greeter → 登录界面不生效。command 交给 greeter 模块。
  programs.niri.enable = true; # 合成器必须由 NixOS 安装（不能只靠 HM），greeter 才能列出

  # 独立 greeter 系统用户（greetd 标准做法）：登录界面以最小权限运行，
  # 用户认证通过后才以目标用户（ran）启动桌面会话。
  # 参考 DMS greeter 模块测试（distro/nix/tests/greeter-niri-module.nix）
  users.groups.greeter = { };
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      # command 由 DMS greeter 模块提供（lib.mkDefault），此处不设置
      user = "greeter";
    };
  };
  # 🔴 关键修复：DMS Greeter 需要 XDG_DATA_DIRS 才能发现 niri 会话（.desktop 文件）。
  # 官方 displayManager 模块会自动注入 `${sessionData.desktops}/share`，但纯 greetd 不走该模块，
  # 必须手动给 greetd 服务加上，否则 greeter 的会话列表为空 → 登录后无法启动 niri。
  systemd.services.greetd.environment.XDG_DATA_DIRS =
    "${config.services.displayManager.sessionData.desktops}/share";
  # 开机弹性：慢启动（user 管理器/dbus 未就绪）时别让 greetd 5 次/10s 就 start-limit-hit，
  # 放宽到 30 次/5 分钟，给系统时间自己稳定下来
  systemd.services.greetd.serviceConfig = {
    StartLimitIntervalSec = "300";
    StartLimitBurst = 30;
  };
  # ============ 蓝牙（DMS bluez 面板 + 笔记本日常）============
  hardware.bluetooth.enable = true;
  # ============ 基础服务 ============
  services.udisks2.enable = true; # U 盘自动挂载（udiskie）
  services.gvfs.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true; # niri 屏幕共享/portal
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "*";
  };

  programs.fuse.userAllowOther = true; # 肥猫云 AppImage 需要
  # ============ 基础工具（应用用户自行重装）============
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    xorg.xhost
    polkit_gnome
    wlsunset
    distrobox
    podman # 容器运行时
    fuse-overlayfs # 可选，提升容器内 FUSE 性能
    appimage-run
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
    # 桌面必需二进制（NixOS 系统层安装，HM 只管配置）
    kitty
    hyprlock
    grim
    slurp
    wl-clipboard
    mpv
    # 通知/截图标注/亮度（niri spawn + HM 配置引用）
    swaynotificationcenter # swaync（niri spawn-at-startup）
    satty # 截图标注（niri 绑定调用）
    brightnessctl # 亮度调节（niri 绑定）
    # 文件管理（mimeapps 默认应用 + Thunar 右键动作）
    nautilus
    thunar
    imv
    # 浏览器（mimeapps 默认应用）
    google-chrome
    # X11 兼容（niri 26.04 经 xwayland-satellite 提供 X11 应用支持）
    xwayland-satellite
    xorg.xhost # 允许 root 经用户 xwayland 开窗
    # 护眼 / 闲置锁屏（niri 脚本依赖）
    wlsunset
    swayidle
    # 工具脚本与右键动作依赖
    libnotify # notify-send
    python3
    mediainfo
    # 认证代理（niri spawn-at-startup）
    polkit_gnome
  ];

  # ============ 字体（kitty/fcitx5 的 Maple Mono NF CN + 中文字体）============
  fonts.packages = with pkgs; [
    maple-mono.NF-CN # "Maple Mono NF CN"（kitty + fcitx5 classicui 指定）
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans # 中文回退
    noto-fonts
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
    trusted-users = [
      "root"
      "@wheel"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  # 系统级自动 GC（保留 14 天）
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  # use appimage on nixos

  programs.appimage = {
    enable = true;
    binfmt = true; # 允许直接执行
  };

  #dms (DankMaterialShell, 模块来自 dms flake input: dms.nixosModules.default)

  programs.dank-material-shell = {
    enable = true;

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dms-shell changes
    };

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)

  };

  # DMS Greeter 登录界面（模块来自 dms flake input: dms.nixosModules.greeter）
  # 自动接管 services.greetd 的 default_session.command，开机显示 DMS 登录界面
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri"; # 用 niri 跑 greeter 界面（必须 NixOS 安装）
    # 同步用户 DMS 主题/壁纸/配色到 greeter（settings.json/session.json/dms-colors.json）
    configHome = "/home/ran";
    # 保存 greeter 日志方便排查
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };
  };

  #distrobox（依赖 rootless podman；NixOS 正确姿势是 virtualisation.podman，
  #手写 systemd.services.podman 会与 podman 自带单元冲突变成 bad-setting）
  virtualisation.podman = {
    enable = true;
    # 让普通用户无需 root 就能跑容器（distrobox 依赖）
    dockerSocket.enable = true;
  };
}
