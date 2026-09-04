# NixOS 配置 —— HP OMEN 16-wf0xxx (ran)

> 单仓库架构（2026-08 合并）：
> - **本仓库**（nixos-config）：系统级配置 + 用户级配置（home/ 目录）一体化
> - 用户级配置原独立仓库 [home-manager-ran](https://github.com/jackockzuo/home-manager-ran) 已并入 `home/` 子目录
> - 配置修改**唯一权威依据**：`STANDARDS.md`（准则文档，含架构/目录/格式/秘密/磁盘规范）

## 一、架构说明

```
nixos-config（单仓库，44 个 .nix，目录 ≤2 层 —— STANDARDS §2 量化规则）
├── flake.nix              # flake-parts 入口：flake.nixosConfigurations.omen + treefmt/git-hooks
├── STANDARDS.md           # 配置准则（唯一权威修改依据，含架构量化规则）
├── hardware-configuration.nix  # 硬件检测 + fileSystems（nixos-generate-config 产物）
├── modules/               # 系统级 15 个文件 + default.nix（扁平，default.nix 聚合地图）
│   └── default.nix        # 聚合入口（每行 imports 带职责注释 = 定位地图）
├── packages/              # 仓库内打包（非 nixpkgs 上游）
│   └── omencore/          # OmenCore（HP OMEN 控制中心，官方 release 二进制）
│                          # pi-coding-agent 已改用 nixpkgs 自带（2026-08）
├── docs/                  # 文档（troubleshooting/ 疑难杂症记录）
└── home/                  # 用户级配置（home-manager）
    ├── home.nix           # HM 入口（被 flake.nix 的 users.ran.imports 引用）
    ├── modules/           # 用户级 22 个文件
    │   ├── desktop/       # 7 个（niri/kitty/fcitx5/dms/appearance/misc/default）
    │   ├── tools/         # 12 个（fish/starship/yazi/shell-utils/dev/neovim/...）
    │   ├── core.nix env.nix network.nix  # 顶层领域文件 + network（代理）
    └── source/            # 配置源文件（niri/dms/beautify）
```

> 注意：私有包（fcclient/tomatodo）已完全移出本仓库（2026-08-29），由独立 flake 管理：
>
> ```bash
> nix profile install path:~/Documents/nix-packaging/fcclient   # 安装/更新
> nix profile install path:~/Documents/tomatodo-nix
> nix profile upgrade fcclient tomatodo-nix                     # 一键升级
> ```
>
> 仓库本身不再引用它们（无 path 输入/overlay/占位包），任意机器可 eval。
> 代码质量门禁：`nix fmt`（nixfmt RFC 风格）+ `nix flake check`（statix/deadnix/treefmt 全量校验）。
> disko 声明式分区已回退（2026-08）：fileSystems 由 hardware-configuration.nix 管理；
> 未来接入 disko 须先 `--mode format,mount` 采纳（见 STANDARDS §5）。

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
| OMEN 控制 | omercore CLI/GUI（风扇/监控）+ 功耗墙解锁（EC 0xBA=5 开机自动） | modules/omencore.nix + packages/omencore |
| 工具链 | fastfetch/btop/yazi/neovim 等（home.packages） | home/modules/ |
| 配置 | niri/kitty/fcitx5 全套 `~/.config` | home/source/ |
| 双系统 | GRUB + os-prober（Windows 自动识别） | modules/boot.nix |

## 四、安装后必做

```bash
# 1. 首次登录（初始密码 ran）立即改密码
passwd
# 密码哈希由 sops 管理（STANDARDS §6）：改密码后需同步更新 secrets/secrets.yaml
# 的 user-password 字段（流程见下"改密码"）

# 2. 更新配置（单仓库一次搞定）
cd ~/nixos-config && git pull && sudo nixos-rebuild switch --flake .#omen

# 3. 验证
echo $XDG_CURRENT_DESKTOP   # Niri
fcitx5-remote -t            # 输入法
snapper -c root list        # 滚挂防护
nmcli device                # 网络
```

### 改密码（sops 管理后）

```bash
# 生成新哈希并更新加密文件（会打开 $EDITOR，改 user-password 的值后保存）
mkpasswd -s
nix shell nixpkgs#sops -c sops secrets/secrets.yaml
# 保存后重新 switch 生效：sudo nixos-rebuild switch --flake .#omen
```

## 五、验证状态（2026-08）

- ✅ `nix flake check` 通过（含 treefmt/statix/deadnix 质量门禁）
- ✅ flake-parts 架构：`flake.nixosConfigurations.omen` + `nix fmt` 统一格式化
- ⏸ disko 已回退（2026-08）：`disko.nix` 已删除，fileSystems 由 `hardware-configuration.nix`（by-uuid）管理；重新接入须先重建 disko.nix 并 `--mode format,mount` 采纳（见 STANDARDS §5）
- ✅ `nixos build omen` 成功（含 firefox/chromium/kitty/网络诊断）
- ✅ home-manager 集成：用户 profile 含 fastfetch/btop/yazi/nvim
- ✅ fcitx5 i18n 块 + rime-ice override（系统层接管，HM 只管配置）
- ✅ 单仓库合并：home-manager 已并入 home/ 目录，消除跨仓库 path 引用
