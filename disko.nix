# ============================================================
# disko.nix —— 声明式分区（STANDARDS.md §4 唯一权威磁盘布局）
# 用途：
#   - 全新安装：分区+挂载+装机一步完成（disko-install）
#   - 采纳现有系统（不毁数据）：--mode format,mount（blkid 幂等守护）
# 布局（与 2026-08 现有系统完全一致）：
#   p1  ESP 1G vfat   → /boot
#   p2  btrfs 952.9G  → @=/, @home=/home, @nix=/nix
#                      + /.snapshots、/home/.snapshots（snapper 独立子卷）
# 挂载选项：compress=zstd + noatime（三子卷一致，避免 disko#331 首挂载坑）
# 修改：改此文件 + nixos-rebuild switch（fileSystems 由 disko 自动生成）
# ============================================================
{
  disko.devices.disk.main = {
    type = "disk";
    # 用 by-id（磁盘重排/换口不受影响）；当前机器为 SIX SSD
    device = "/dev/disk/by-id/nvme-SIX_SSD_STX25031900008075";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0022"
              "dmask=0022"
            ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              # 系统三子卷：compress=zstd + noatime（必须完全一致，disko#331）
              "@" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              # snapper 快照目录：独立子卷 + 挂载（快照不递归自身）
              # ⚠️ 禁止声明为"不挂载"子卷（"/.snapshots" = { }）：运行时不可见，
              #    snapper 会报 "IO Error (open failed path:/.snapshots errno:2)"
              "/.snapshots" = {
                mountpoint = "/.snapshots";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/home/.snapshots" = {
                mountpoint = "/home/.snapshots";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };
}
