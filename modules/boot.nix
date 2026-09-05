# ============================================================
# boot.nix —— 引导与内核（平台通用，所有机器统一引导器 = Limine）
# 职责：内核选择 + Limine（catppuccin 风配色/壁纸/多系统）
# GRUB 已停用但保留在本文件注释（回退方法见文件尾 + docs）
# ============================================================
{ pkgs, ... }:

let
  # 内核选择开关
  # "cachyos"  → CachyOS 高性能内核（默认，x86-64-v3 优化）
  # "zen"      → Zen（BORE 调度器）
  # "latest"   → 主线最新
  # "lts"      → 6.12 LTS
  # ⚠️ 切换后 nvidia 模块随内核自动重建
  kernelProfile = "cachyos";
  kernelPackages =
    {
      cachyos = pkgs.linuxPackages_cachyos;
      zen = pkgs.linuxPackages_zen;
      latest = pkgs.linuxPackages_latest;
      lts = pkgs.linuxPackages_6_12;
    }
    .${kernelProfile};

  # Limine 壁纸（可选；catppuccin/limine 官方风格=纯色底。想加壁纸：放 assets/ 并把下面
  #   style.wallpapers = [ <路径> ] 取消注释即可。GRUB 主题文件 assets/grub-theme 保留未动）
in
{
  boot = {
    loader = {
      timeout = 6;
      efi.canTouchEfiVariables = true;

      # ---- 主引导器：Limine（全机统一）----
      limine = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true; # 可移动安装：不写 NVRAM，避免 HP 固件同号重建 exit8（NVRAM 项手工建一次）
        maxGenerations = 5; # 只留最近 5 个 NixOS 镜像
        enableEditor = false; # 关闭编辑（防 init=/bin/sh 提权）
        resolution = "1920x1080x32"; # 内核早期 fb 分辨率（外显友好）

        # ---- 外观：Catppuccin/limine 官方主题（mocha-blue，github.com/catppuccin/limine）----
        style = {
          # wallpapers = [ ../assets/limine/background.png ]; # 可选壁纸（预留）
          wallpaperStyle = "stretched";
          backdrop = "1E1E2E"; # mocha base

          interface = {
            resolution = "1920x1080x32"; # Limine 菜单自身分辨率（外显 1080p）
            branding = "NixOS";
            brandingColor = "89B4FA"; # catppuccin mocha blue
            helpColor = "89B4FA";
            helpColorBright = "89B4FA";
          };

          graphicalTerminal = {
            font.scale = "2x2"; # 高分屏清晰（用户指定 scale=2）
            # === catppuccin-mocha-blue.conf（官方值，勿改格式）===
            palette = "1E1E2E;F38BA8;A6E3A1;F9E2AF;89B4FA;F5C2E7;94E2D5;CDD6F4";
            brightPalette = "585B70;F38BA8;A6E3A1;F9E2AF;89B4FA;F5C2E7;94E2D5;CDD6F4";
            background = "1E1E2E";
            foreground = "CDD6F4";
            brightBackground = "585B70";
            brightForeground = "CDD6F4";
            margin = 100; # 呼吸感留白（用户指定）
            marginGradient = 40;
          };
        };

        # ---- 多系统：Windows 11（另一 NVMe 独立 ESP，用固件启动项委托）----
        extraEntries = ''
          /Windows 11
            protocol: efi_boot_entry
            entry: Windows Boot Manager
        '';
      };

      # ---- GRUB 回退（已停用；应急/回退方法见文件尾注释）----
      # 如需回退 GRUB：启用下面块并注释上面 limine.enable，然后 `nr`。
      # 磁盘上的 /boot/EFI/NixOS-boot 与固件项 NixOS-boot(Boot0002) 仍在，可作紧急入口。
      # grub = {
      #   enable = true;
      #   device = "nodev";
      #   efiSupport = true;
      #   efiInstallAsRemovable = true;
      #   useOSProber = true;
      #   theme = ../assets/grub-theme;
      #   configurationLimit = 10;
      # };
    };

    # 由 kernelProfile 决定
    inherit kernelPackages;
    kernelParams = [
      "ibt=off" # nvidia 兼容
      "nvidia-drm.modeset=1"
    ];
  };
}
