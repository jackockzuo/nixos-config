# NixOS 配置 —— HP OMEN 16-wf0xxx (ran)

> 双仓库架构：
> - **本仓库**（nixos-config）：系统级配置（驱动/引导/服务/桌面二进制）
> - **[home-manager-ran](https://github.com/jackockzuo/home-manager-ran)**：用户级配置（niri/kitty/fcitx5 等全部 `~/.config` + 工具链）

## 一、架构说明

```
nixos-config（系统层）
├── flake.nix              # omen 配置：导入 configuration + hardware + hm-ran
├── configuration.nix      # 系统：GRUB双系统/NVIDIA/音频/输入法/greetd/联网工具
├── hardware-configuration.nix  # @home 保留（零备份迁移）
└── migrate.md             # 迁移详细指南

home-manager-ran（用户层，被 flake 引用）
└── home.nix + modules/    # niri/kitty/fcitx5/neovim/工具链配置（自动生效）
```

## 二、毛坯房快速搭建（全新 NixOS → 完整系统）

### 全新安装（无旧系统）

```bash
# 1. 分区 nvme1n1：EFI 1G + btrfs 剩余
parted -s /dev/nvme1n1 mklabel gpt
parted -s /dev/nvme1n1 mkpart ESP fat32 1MiB 1GiB
parted -s /dev/nvme1n1 set 1 esp on
parted -s /dev/nvme1n1 mkpart primary btrfs 1GiB 100%

# 2. 建子卷 + 挂载
mkfs.fat -F32 /dev/nvme1n1p1
mkfs.btrfs -f /dev/nvme1n1p2
mount /dev/nvme1n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@home
umount /mnt
mount -o subvol=@,compress=zstd:3,noatime /dev/nvme1n1p2 /mnt
mkdir -p /mnt/nix /mnt/home /mnt/boot
mount -o subvol=@nix,compress=zstd:3,noatime /dev/nvme1n1p2 /mnt/nix
mount -o subvol=@home,compress=zstd:3,noatime /dev/nvme1n1p2 /mnt/home
mount /dev/nvme1n1p1 /mnt/boot

# 3. 生成硬件配置（真实 UUID）+ 拉取配置
nixos-generate-config --root /mnt
git clone https://github.com/jackockzuo/nixos-config.git /mnt/dotfiles
git clone https://github.com/jackockzuo/home-manager-ran.git /mnt/home/ran/.config/home-manager 2>/dev/null || true
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/dotfiles/

# 4. 安装
cd /mnt/dotfiles
nixos-install --flake .#omen
```

## 三、安装后（自动生效的）

| 类别 | 内容 | 来源 |
|---|---|---|
| 桌面 | niri（greetd 直启）+ kitty + hyprlock | nixos-config + HM |
| 输入法 | fcitx5-rime（雾凇）+ catppuccin 主题 | 系统层 + HM |
| 联网 | firefox/chromium + wget + 网络诊断 | nixos-config |
| 工具链 | fastfetch/btop/yazi/neovim 等（HM home.packages） | home-manager-ran |
| 配置 | niri/kitty/fcitx5 全套 `~/.config` | home-manager-ran |
| 双系统 | GRUB + os-prober（Windows 自动识别） | nixos-config |

## 四、安装后必做

```bash
# 1. 首次登录（初始密码 ran）立即改密码
passwd
# 然后删掉 configuration.nix 的 initialPassword 行再 rebuild

# 2. 更新配置（HM 在 @home 里，直接可更新）
cd ~/nixos-config && git pull && sudo nixos-rebuild switch --flake .#omen
cd ~/.config/home-manager && git pull && nixos-rebuild switch --flake ~/nixos-config#omen

# 3. 验证
echo $XDG_CURRENT_DESKTOP   # Niri
fcitx5-remote -t            # 输入法
snapper -c root list        # 滚挂防护
nmcli device                # 网络
```

## 五、验证状态（2026-08）

- ✅ `nix flake check` 通过
- ✅ `nixos build omen` 成功（含 firefox/chromium/kitty/网络诊断）
- ✅ home-manager 集成：用户 profile 含 fastfetch/btop/yazi/nvim
- ✅ fcitx5 i18n 块 + rime-ice override（系统层接管，HM 只管配置）
