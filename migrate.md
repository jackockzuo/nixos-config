# 迁移指南：Arch → NixOS（HP OMEN 16-wf0xxx）

> 数据保留策略：**零备份** —— `/home` 是独立 btrfs 子卷 `@home`，重装只删除根子卷 `@`，
> `@home` 原样保留 → Documents(108G)/Pictures/Downloads/**肥猫云 AppImage** 全部原地不动。
> nvme0n1（Windows 盘）完全不动。

## 准备

1. **下载 NixOS ISO**（最小版即可）：
   - 官方：https://nixos.org/download/ （nixos-minimal-x86_64-linux）
   - 国内镜像：https://mirrors.tuna.tsinghua.edu.cn/nixos-images/
2. **写入 U 盘**（在 Arch 上执行）：
   ```bash
   sudo dd if=/path/to/nixos.iso of=/dev/sdX bs=4M status=progress
   ```
3. 本配置已放在 `~/nixos-config/`（**在 @home 里，重装后自动还在**）
4. 可选：清一下缓存省空间 `rm -rf ~/.cache/*`（约 100G，可留）

## 安装步骤

### 1. 引导 U 盘，进入 Live CD

### 2. 分区操作（关键！保留 @home）

```bash
# 挂载 btrfs 顶层（能看到所有子卷）
mount /dev/nvme1n1p2 /mnt

# 查看现有子卷，确认 @home 在
btrfs subvolume list /mnt

# 删除旧 Arch 子卷（只删 @ 和 var/cache 等，【千万不要删 @home】）
btrfs subvolume delete /mnt/@
btrfs subvolume delete /mnt/@var 2>/dev/null || true
btrfs subvolume delete /mnt/@cache 2>/dev/null || true
btrfs subvolume list /mnt    # 确认 @home 还在！

# 创建 NixOS 子卷
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@nix

# 重新挂载
umount /mnt
mount -o subvol=@,compress=zstd:3,noatime /dev/nvme1n1p2 /mnt
mkdir -p /mnt/nix /mnt/home /mnt/boot
mount -o subvol=@nix,compress=zstd:3,noatime /dev/nvme1n1p2 /mnt/nix
mount -o subvol=@home,compress=zstd:3,noatime /dev/nvme1n1p2 /mnt/home
mount /dev/nvme1n1p1 /mnt/boot   # EFI

# 验证数据在！
ls /mnt/home/ran/Documents | head    # 应该能看到你的文件
```

### 3. 安装

```bash
# 关键：把 @home bind-mount 到 Live CD 的 /home
# （flake 和 HM 配置都在 @home 里，路径需要在这里可解析）
mkdir -p /home
mount --bind /mnt/home /home

# 验证
ls /home/ran/nixos-config        # 应该有 flake.nix
ls /home/ran/.config/home-manager/home.nix

# 安装（flake 里导入了 @home 里的 HM 配置）
nixos-install --flake /home/ran/nixos-config#omen

# 过程中设置 ran 的密码
# 建议同时设 root 密码
```

### 4. 重启

```bash
reboot
```

## 重启后验证

```bash
# 0. 首次登录（初始密码是 ran，立即修改）
passwd
# 然后删掉 configuration.nix 里的 initialPassword 行：
#   sudo nixos-rebuild switch --flake ~/nixos-config#omen

# 1. 数据完整
ls ~/Documents ~/Pictures ~/Downloads

# 2. 肥猫云（AppImage 已在 ~/.local/share/applications/）
#    首次运行：chmod +x ~/.local/share/applications/fcclient-*.AppImage
#    直接双击或运行即可（fuse 已配置）
#    autostart 桌面文件在 ~/.config/autostart/ 里，自动开机启动

# 3. 输入法（fcitx5 系统级，Ctrl+Space 切换，配置由 HM 接管）
# 4. Windows 双系统：GRUB 菜单里应有 Windows（os-prober）
```

## 应用重装（"之后再重新安装"）

你的 **HM 配置已自动生效**（flake 里导入了 `~/.config/home-manager/home.nix`）——
fastfetch/btop/yazi/kitty/niri 配置等**自动回来**。需要补的：

```bash
# 系统级应用（原来是 pacman 的）：
sudo nixos-rebuild switch --flake ~/nixos-config#omen
# 在 configuration.nix 的 environment.systemPackages 里加：
#   google-chrome、kate、ark、wireshark、clash-verge-rev、mathematica...

# 或临时跑：nix shell nixpkgs#google-chrome -c google-chrome-stable
```

## 迁移后需要调整的 HM 配置（重要）

1. **fcitx5**：HM 的 `modules/fcitx5.nix` 里 `i18n.inputMethod` 块删掉（系统层已管），保留 `xdg.configFile` 部分
2. **GC**：HM 的 `nix-gc` 定时器可删（系统层 `nix.gc.automatic` 已管）
3. **nix.settings**：HM 里的 `nix` 块可简化（客户端设置保留也无害）

## 回退

- Arch 分区未动之前：GRUB 里仍可选旧系统
- 万一失败：`btrfs subvolume delete /mnt/@` 后 Arch 的 @ 已删——所以**建议先在 VM 里试装一次**，或迁移前把 nixos-config 跑通 `nix flake check`
