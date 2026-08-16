# ============================================================
# boot.nix —— 引导与内核
# 职责：GRUB 双系统引导、内核版本、内核参数
# 修改：换引导/加内核参数 → 改这里
# 关联：hardware.nix（NVIDIA 需要 nvidia-drm 参数）
# ============================================================
{ pkgs, ... }:

{
  # ============ 引导：GRUB（实际引导链是 GRUB，从 Arch 时代继承）============
  # 🔴 实际排查：固件从 /boot/EFI/NixOS-boot/grubx64.efi (GRUB) 引导，加载 /boot/grub/grub.cfg。
  # NixOS 的 systemd-boot 条目从不被使用 → 每次 switch 只更新 systemd-boot 条目，
  # GRUB 菜单仍指向旧代 → 重启后加载旧系统。
  # 改为 NixOS 管理 GRUB：switch 时自动更新 grub.cfg 指向最新代。
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev"; # EFI 模式
      efiSupport = true;
      efiInstallAsRemovable = true; # 安装为 removable 路径，确保固件能找到
      # 🔴 跨盘发现 Windows：Windows 在另一块盘 (nvme1n1)，os-prober 扫描所有磁盘
      # 的 EFI 系统分区，在 GRUB 菜单添加 Windows Boot Manager 条目
      useOSProber = true;
      # 🎨 GRUB 主题：catppuccin-mocha 风格 + NixOS 雪花 logo（logo 已替换，
      # 主题文件在仓库 assets/grub-theme/，由 NixOS 声明式管理，不再手装）
      theme = ../assets/grub-theme;
    };
  };

  # ============ 内核：最新（≈ 现在的 7.1.x）============
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "ibt=off" # nvidia 兼容（KVM 直通/嵌套虚拟化需要）
    "nvidia-drm.modeset=1"
  ];
}
