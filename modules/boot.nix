# ============================================================
# boot.nix —— 引导与内核
# 职责：GRUB 双系统引导、内核版本、内核参数
# 修改：换引导/加内核参数 → 改这里
# 关联：hardware.nix（NVIDIA 需要 nvidia-drm 参数）
# ============================================================
{ pkgs, ... }:

let
  # ============ 内核选择开关（改这一行即可切换，随时切回）============
  # "cachyos"  → CachyOS 高性能内核（默认，来自 chaotic overlay，x86-64-v3 优化）
  # "zen"      → Zen（BORE 调度器，nixpkgs 内建，nvidia 自动配对）
  # "latest"   → 主线最新（原默认 7.1.x）
  # "lts"      → 6.12 LTS（求稳）
  # ⚠️ 切换后 nvidia 模块随内核自动重建（构建期验证，失败则不切换）
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
    # ============ 引导：GRUB（实际引导链是 GRUB，从 Arch 时代继承）============
    # 🔴 实际排查：固件从 /boot/EFI/NixOS-boot/grubx64.efi (GRUB) 引导，加载 /boot/grub/grub.cfg。
    # NixOS 的 systemd-boot 条目从不被使用 → 每次 switch 只更新 systemd-boot 条目，
    # GRUB 菜单仍指向旧代 → 重启后加载旧系统。
    # 改为 NixOS 管理 GRUB：switch 时自动更新 grub.cfg 指向最新代。
    loader = {
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

    # ============ 内核：由上方 kernelProfile 决定（2026-08-17 默认 CachyOS）============
    # 选型依据（用户需求：桌面视频 + 性能计算）：
    #   - CachyOS：BORE 调度 + x86-64-v3 优化 + cachyos-settings，性能计算/桌面响应兼顾
    #   - scx_lavd 调度器叠加（services.nix），针对交互+计算并行优化
    #   - nvidia 595 驱动经 boot.kernelPackages 自动配对（nyx 缓存有预编译）
    #   回滚：GRUB 旧 generation 一键回退；或改 kernelProfile 一行切回 zen/latest/lts
    kernelPackages = kernelPackages;
    kernelParams = [
      "ibt=off" # nvidia 兼容（KVM 直通/嵌套虚拟化需要）
      "nvidia-drm.modeset=1"
    ];
  };
}
