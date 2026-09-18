# ============================================================
# boot.nix —— 引导与内核（平台通用）
# 职责：内核选择 + Limine 通用开关（启用/代际）+ zram + 通用内核参数
# 机器专属（Limine 外观/品牌/分辨率/多系统条目/nvidia 参数）→ hosts/<machine>/boot.nix
# ============================================================
{ pkgs, lib, ... }:

let
  # 内核选择开关
  # "zen"      → Zen 高性能内核（默认，BORE 调度器；kernel/modules/dev 走国内镜像）
  # "latest"   → 主线最新
  # "lts"      → 6.12 LTS
  # ⚠️ 切换后 nvidia 模块随内核自动重建
  # 注：原 "cachyos" 选项随 chaotic-nyx 一并移除（其缓存无国内镜像，内核更新极慢）
  kernelProfile = "zen";
  kernelPackages =
    {
      zen = pkgs.linuxPackages_zen;
      latest = pkgs.linuxPackages_latest;
      lts = pkgs.linuxPackages_6_12;
    }
    .${kernelProfile};
in
{
  boot = {
    tmp = {
      useZram = true; # 启用 zram 作为 /tmp
      cleanOnBoot = true; # 关机/重启时清理残留
      zramSettings = {
        # 虚拟容量设为物理内存的 1.0 ~ 1.5 倍（依靠 zstd 压缩，实际上不会占满物理内存）
        zram-size = "ram * 1.0";
        compression-algorithm = "zstd"; # 压缩比和速度非常均衡
        fs-type = "ext4";
      };
    };

    loader = {
      timeout = null; # 不自动进系统，进菜单手动选择
      efi.canTouchEfiVariables = true;

      # ---- 主引导器：Limine（全机统一，可移动安装免 NVRAM 冲突）----
      limine = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true; # 装到 \EFI\BOOT；NVRAM 项已手工建一次，勿再让模块建
        maxGenerations = 3; # 菜单只留最近 3 代（ESP 容量限制）；外观/多系统在 hosts/<machine>/boot.nix
        enableEditor = true;
      };
    };

    # 由 kernelProfile 决定（mkDefault：specialisation 多内核可覆盖，见 hosts/<machine>/multikernel.nix）
    kernelPackages = lib.mkDefault kernelPackages;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "vt.global_cursor_default=0"
    ];
  };
}
