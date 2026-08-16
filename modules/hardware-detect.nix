# ============================================================
# hardware-detect.nix —— 硬件检测（nixos-generate-config 产物，去 fileSystems）
# 职责：initrd 内核模块、CPU 微码、平台声明
# 注意：fileSystems/swapDevices 已由 disko 接管（见 disko.nix，STANDARDS §4.1）
# 重新生成方式：nixos-generate-config --no-filesystems --root /mnt
# ============================================================
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
