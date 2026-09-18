#!/usr/bin/env bash
# fix-password.sh — 2026-08-17 恢复脚本：写入修复后的密码哈希并验证
# 用法（live ISO 或 nixos-enter 里都行）：
#   sudo bash /mnt/home/ran/nixos-config/fix-password.sh   (live ISO)
#   bash /home/ran/nixos-config/fix-password.sh            (nixos-enter 内)
# 🔴 不在脚本内硬编码口令：运行时交互输入（REF:2026-08-17-niri-login-sops-password）
set -e

PPL=/nix/store/rk0p1mw6l95s99k4f0p2mk5z2qxv8gcz-perl-5.42.0-env/bin/perl
UGP=/nix/store/dyx8qsmgnsz2csfzwn723gbd2jvp0j7g-update-users-groups.pl
UGJ=/nix/store/zggr7y3vg5a67dic34hxy9aiwc2b85ay-users-groups.json
BTRFS=/dev/disk/by-uuid/42701c28-c857-4f68-883a-125c1e985b33
BOOT=/dev/disk/by-uuid/71C7-34C8

do_fix() {
  local user="${1:-ran}" pw=""
  echo "==> [1/2] 写入密码哈希到 /etc/shadow ..."
  "$PPL" -w "$UGP" "$UGJ" || true

  printf '==> [2/2] 验证 %s 的密码（输入期望口令，不回显）: ' "$user"
  read -rs pw
  echo
  local hash
  hash=$(grep "^${user}:" /etc/shadow | cut -d: -f2)
  # 口令经环境变量传给 perl，避免出现在 ps 的 argv 中
  if [ -n "$hash" ] && PW="$pw" "$PPL" -e 'exit(crypt($ENV{PW}, $ARGV[0]) eq $ARGV[0] ? 0 : 1)' "$hash"; then
    echo ""
    echo "✅ 密码验证通过。"
    echo "   接下来：exit 退出（若在 chroot 里）→ sudo reboot"
    return 0
  else
    echo ""
    echo "❌ 验证失败！请勿重启，先检查 sops 密码链（见事故档）。"
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
