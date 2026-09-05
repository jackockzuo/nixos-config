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

  # 纯色版：无壁纸资产，底色由 style.backdrop 提供（catppuccin mocha base）
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
          backdrop = "1E1E2E"; # catppuccin mocha base 纯色背景

          interface = {
            resolution = "2560x1600x32"; # Limine 菜单 = 内屏原生(eDP)
            branding = "NixOS";
            brandingColor = "89B4FA"; # catppuccin mocha blue
            helpColor = "89B4FA";
            helpColorBright = "F9E2AF";
          };

          graphicalTerminal = {
            # 视觉调优（Limine 仅位图字库，无 TTF）：scale=2 保证高分清晰，spacing=1 致密
            font = {
              scale = "2x2";
              spacing = 1;
            };
            palette = "45475A;F38BA8;A6E3A1;F9E2AF;89B4FA;CBA6F7;94E2D5;BAC2DE";
            brightPalette = "585B70;F38BA8;A6E3A1;F9E2AF;89B4FA;CBA6F7;94E2D5;CDD6F4";
            foreground = "CDD6F4";
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
