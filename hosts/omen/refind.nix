# refind.nix —— rEFInd + Minimalist 主题引导（主机专属，2026-09-05）
# 说明：rEFInd 由 boot.loader.refind 管理，注册固件启动项 \EFI\refind\refind_x64.efi；
#       旧 GRUB（Boot0002 NixOS-boot）文件与 NVRAM 项保留作回退（勿删 /boot/EFI/NixOS-boot）。
# 主题：assets/refind-minimal（evanpurkhiser/rEFInd-minimal，vendor 进仓库），
#       icons 含 os_nixos/os_arch/os_win 等，开机经 tmpfiles 复制到 ESP。
# 回退：把本文件从 hosts/omen/default.nix imports 移除 + `nr`（重开 GRUB 模块）即可。
# ============================================================
{ lib, ... }:

let
  themeDir = ../../assets/refind-minimal;
in
{
  imports = [ ];

  # —— 用 rEFInd 取代 GRUB（共享层 boot.nix 仍默认 GRUB，供其它主机）——
  boot.loader.grub.enable = lib.mkForce false;

  boot.loader = {
    timeout = 6;
    efi.canTouchEfiVariables = lib.mkDefault true;

    refind = {
      enable = true;
      efiInstallAsRemovable = false; # 写 NVRAM 项；可回退项见 GRUB Boot0002
      extraConfig = ''
        # Minimalist 主题（include 相对 /EFI/refind）
        include themes/refind-minimal/theme.conf
        # 扫描：本机多系统盘（Windows ESP 在其它 NVMe）
        scanfor internal,external,optical,biosexternal
      '';
    };
  };

  # 把主题复制到 ESP（tmpfiles C = 每次开机递归拷贝；切换后手动跑一次即可预置）
  systemd.tmpfiles.rules = [
    "C! /boot/EFI/refind/themes/refind-minimal - - - - ${themeDir}"
  ];
}
