# boot.nix —— 引导与内核
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
in
{
  boot = {
    # GRUB 引导（固件实际从 /boot/EFI/NixOS-boot/grubx64.efi 引导，非 systemd-boot）
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
        useOSProber = true; # 跨盘发现 Windows
        theme = ../assets/grub-theme;
        configurationLimit = 10; # 菜单只保留最近 10 代
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
