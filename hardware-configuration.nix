# 硬件配置 - HP OMEN 16-wf0xxx (ran)
# 已按当前分区预填（@home 保留策略）。
# 安装时建议在 Live CD 里跑 nixos-generate-config 生成精确版再合并。
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # ============ 文件系统（关键：@home 保留，数据零丢失）============
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/42701c28-c857-4f68-883a-125c1e985b33";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd:3" "noatime" ];
  };

  # /home 是独立子卷 @home —— 重装只删 @，这里原样挂回
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/42701c28-c857-4f68-883a-125c1e985b33";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd:3" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/71C7-34C8";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # 交换由 zram 处理（configuration.nix）
  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
