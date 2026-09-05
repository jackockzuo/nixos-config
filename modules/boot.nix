# ============================================================
# boot.nix —— 引导与内核（平台通用，所有机器统一引导器 = Limine）
# 职责：内核选择 + Limine（catppuccin 风配色/壁纸/多系统）
# 2026-09-05：仅 Limine（可移动安装 \EFI\BOOT，不写 NVRAM；启动项手工建一次）。
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

  # 4 张蓝色调壁纸（PNG 2560x1600，每次开机随机一张；jpg 源已删）
  wallpapers = map (f: ../assets/wallpaper/${f}) [
    "img1.wallspic.com-particle-shape-electric_blue-blue-fractal_art-3840x2160.png"
    "img2.wallspic.com-electric_blue-azure-light-space-symmetry-3840x2400.png"
    "img2.wallspic.com-purple-light-space-blue-atmosphere-2560x1600.png"
    "img3.wallspic.com-creative_arts-energy-graphics-space-symmetry-2560x1600.png"
  ];
in
{
  boot = {
    loader = {
      timeout = null; # 不自动进系统，进菜单手动选择
      efi.canTouchEfiVariables = true;

      # ---- 主引导器：Limine（全机统一，可移动安装免 NVRAM 冲突）----
      limine = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true; # 装到 \EFI\BOOT；NVRAM 项已手工建一次，勿再让模块建
        maxGenerations = 5; # 只留最近 5 个 NixOS 镜像
        enableEditor = false; # 关闭编辑（防 init=/bin/sh 提权）
        resolution = "2560x1600x32"; # 内核早期 fb = 内屏原生(eDP)

        # ---- 外观：catppuccin mocha 配色 + 极简 ----
        style = {
          wallpapers = wallpapers;
          wallpaperStyle = "stretched";
          backdrop = "0B1E33"; # 深蓝兜底（壁纸加载前/居中时）

          interface = {
            resolution = "2560x1600x32"; # Limine 菜单 = 内屏原生(eDP)
            branding = "NixOS";
            brandingColor = "6FB1FF"; # 电蓝主色（配蓝图）
            helpColor = "9AC8FF";
            helpColorBright = "E6F1FF";
          };

          graphicalTerminal = {
            # 视觉调优（Limine 仅位图字库，无 TTF）：scale=2 保证高分清晰，spacing=1 致密
            font = {
              scale = "2x2";
              spacing = 1;
            };
            # 冷蓝协调：冷白前景 + 半透明深蓝底幕（四张蓝图通吃可读）
            palette = "0B1E33;4FA3FF;7FD0FF;9AC8FF;4FA3FF;C6A9FF;8FE3FF;E6F1FF";
            brightPalette = "14263F;6FB1FF;9FD8FF;B8D9FF;6FB1FF;DDC6FF;AFE9FF;FFFFFF";
            foreground = "E6F1FF";
            background = "990B1E33"; # TT=99(≈60%) 深蓝底幕，防止亮图吃字
            margin = 120; # 呼吸感留白
            marginGradient = 60;
          };
        };

        # ---- 多系统：Windows 11（另一 NVMe 独立 ESP，固件启动项委托）----
        extraEntries = ''
          /Windows 11
            protocol: efi_boot_entry
            entry: Windows Boot Manager
        '';
      };
    };

    # 由 kernelProfile 决定
    inherit kernelPackages;
    kernelParams = [
      "ibt=off" # nvidia 兼容
      "nvidia-drm.modeset=1"
    ];
  };
}
