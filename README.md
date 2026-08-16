# NixOS 配置 —— HP OMEN 16-wf0xxx (ran)

> 单仓库架构（2026-08 合并）：
> - **本仓库**（nixos-config）：系统级配置 + 用户级配置（home/ 目录）一体化
> - 用户级配置原独立仓库 [home-manager-ran](https://github.com/jackockzuo/home-manager-ran) 已并入 `home/` 子目录

## 一、架构说明

```
nixos-config（单仓库）
├── flake.nix              # omen 配置：导入 modules/ + home/ + hardware + secrets
├── hardware-configuration.nix  # @home 保留（零备份迁移）
├── modules/               # 系统级模块（boot/hardware/network/users/desktop/...）
└── home/                  # 用户级配置（home-manager）
    ├── home.nix           # HM 入口（被 flake.nix 的 users.ran.imports 引用）
    ├── modules/           # 用户级模块（desktop/tools/network/...）
    └── source/            # 配置源文件（niri/dms/beautify）
```

> 注意：`secrets`（GitHub token）与 `fcclientPkg`（肥猫云客户端）仍在仓库外，
> 通过 `path:` 输入引用（保持本仓库纯净，.deb/token 不进 git）。

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

# 3. 生成硬件配置（真实 UUID）+ 拉取配置（单仓库，只需克隆一次）
nixos-generate-config --root /mnt
git clone https://github.com/jackockzuo/nixos-config.git /mnt/dotfiles
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/dotfiles/

# 4. 安装
cd /mnt/dotfiles
nixos-install --flake .#omen
```

## 三、安装后（自动生效的）

| 类别 | 内容 | 来源 |
|---|---|---|
| 桌面 | niri（greetd 直启）+ kitty + hyprlock | modules/desktop.nix + home/ |
| 输入法 | fcitx5-rime（雾凇）+ catppuccin 主题 | 系统层 + home/ |
| 联网 | firefox/chromium + wget + 网络诊断 | modules/packages.nix |
| 工具链 | fastfetch/btop/yazi/neovim 等（home.packages） | home/modules/ |
| 配置 | niri/kitty/fcitx5 全套 `~/.config` | home/source/ |
| 双系统 | GRUB + os-prober（Windows 自动识别） | modules/boot.nix |

## 四、安装后必做

```bash
# 1. 首次登录（初始密码 ran）立即改密码
passwd
# 然后删掉 users.nix 的 initialPassword 行再 rebuild

# 2. 更新配置（单仓库一次搞定）
cd ~/nixos-config && git pull && sudo nixos-rebuild switch --flake .#omen

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
- ✅ 单仓库合并：home-manager 已并入 home/ 目录，消除跨仓库 path 引用
