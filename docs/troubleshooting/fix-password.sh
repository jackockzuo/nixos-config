#!/usr/bin/env bash
# fix-password.sh — 2026-08-17 恢复脚本：写入修复后的密码哈希并验证
# 用法（live ISO 或 nixos-enter 里都行）：
#   sudo bash /mnt/home/ran/nixos-config/fix-password.sh   (live ISO)
#   bash /home/ran/nixos-config/fix-password.sh            (nixos-enter 内)
set -e

PPL=/nix/store/rk0p1mw6l95s99k4f0p2mk5z2qxv8gcz-perl-5.42.0-env/bin/perl
UGP=/nix/store/dyx8qsmgnsz2csfzwn723gbd2jvp0j7g-update-users-groups.pl
UGJ=/nix/store/zggr7y3vg5a67dic34hxy9aiwc2b85ay-users-groups.json
BTRFS=/dev/disk/by-uuid/42701c28-c857-4f68-883a-125c1e985b33
BOOT=/dev/disk/by-uuid/71C7-34C8

do_fix() {
  echo "==> [1/2] 写入密码哈希到 /etc/shadow ..."
  "$PPL" -w "$UGP" "$UGJ" || true

  echo "==> [2/2] 验证密码 ran ..."
  HASH=$(grep "^ran:" /etc/shadow | cut -d: -f2)
  if [ -n "$HASH" ] && "$PPL" -e 'exit(crypt("ran", $ARGV[0]) eq $ARGV[0] ? 0 : 1)' "$HASH"; then
    echo ""
    echo "✅ 密码验证通过！密码 = ran"
    echo "   接下来：exit 退出（若在 chroot 里）→ sudo reboot"
    echo "   重启后 GRUB 会引导新系统（Configuration 53），用 ran / ran 登录。"
    return 0
  else
    echo ""
    echo "❌ 验证失败！请把输出发给 Sisyphus，不要重启。"
    return 1
  fi
}

if [ -e "$UGJ" ]; then
  # 已经在 chroot / nixos-enter 里
  do_fix
else
  # live ISO：先挂载再进 chroot
  echo "==> 挂载系统分区 ..."
  mkdir -p /mnt
  mountpoint -q /mnt  || mount -o subvol=@ "$BTRFS" /mnt
  mkdir -p /mnt/nix /mnt/home /mnt/boot
  mountpoint -q /mnt/nix  || mount -o subvol=@nix "$BTRFS" /mnt/nix
  mountpoint -q /mnt/home || mount -o subvol=@home "$BTRFS" /mnt/home
  mountpoint -q /mnt/boot || mount "$BOOT" /mnt/boot
  chroot /mnt /bin/bash -c 'bash /home/ran/nixos-config/fix-password.sh'
fi
