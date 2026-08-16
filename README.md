# NixOS 配置 —— HP OMEN 16-wf0xxx (ran)

> 单仓库架构（2026-08 合并）：
> - **本仓库**（nixos-config）：系统级配置 + 用户级配置（home/ 目录）一体化
> - 用户级配置原独立仓库 [home-manager-ran](https://github.com/jackockzuo/home-manager-ran) 已并入 `home/` 子目录
> - 配置修改**唯一权威依据**：`STANDARDS.md`（准则文档，含架构/目录/格式/秘密/磁盘规范）

## 一、架构说明

```
nixos-config（单仓库）
├── flake.nix              # flake-parts 入口：flake.nixosConfigurations.omen + treefmt/git-hooks/disko
├── STANDARDS.md           # 配置准则（唯一权威修改依据）
├── disko.nix              # 声明式分区（btrfs 子卷 + compress + .snapshots，见 STANDARDS §4）
├── modules/               # 系统级模块（boot/hardware-detect/network/users/desktop/...）
└── home/                  # 用户级配置（home-manager）
    ├── home.nix           # HM 入口（被 flake.nix 的 users.ran.imports 引用）
    ├── modules/           # 用户级模块（desktop/tools/network/...）
    └── source/            # 配置源文件（niri/dms/beautify）
```

> 注意：`secrets`（GitHub token）与 `fcclientPkg`（肥猫云客户端）仍在仓库外，
> 通过 `path:` 输入引用（保持本仓库纯净，.deb/token 不进 git）。
> 代码质量门禁：`nix fmt`（nixfmt RFC 风格）+ `nix flake check`（statix/deadnix/treefmt 全量校验）。
> 磁盘布局唯一权威：`disko.nix`（fileSystems 由 disko 自动生成，不再手写 hardware-configuration.nix）。

## 二、毛坯房快速搭建（全新 NixOS → 完整系统）

### 全新安装（无旧系统）

```bash
# 1. 分区 + 挂载：声明式（disko 接管，见 disko.nix，STANDARDS §4）
#    disko-install 一步完成：分区/格式化/挂载/生成配置/安装
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --flake /home/ran/nixos-config#omen \
  --disk main /dev/disk/by-id/nvme-SIX_SSD_STX25031900008075
# （等价手动流：disko --mode destroy,format,mount disko.nix → nixos-generate-config → nixos-install）

# 2. 拉取配置（单仓库，只需克隆一次）
git clone https://github.com/jackockzuo/nixos-config.git /mnt/dotfiles

# 3. 安装
cd /mnt/dotfiles
nixos-install --flake .#omen
```

> ⚠️ 注意事项：本仓库已用 disko 声明式管理分区（disko.nix），fileSystems 不再从
> hardware-configuration.nix 读取。新装机时**不需要** cp hardware-configuration.nix
> （旧版本流程遗留），硬件检测部分已固化在 modules/hardware-detect.nix。
> 若用 nixos-generate-config 生成，仅用于核对硬件差异，勿覆盖 disko 配置。

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

- ✅ `nix flake check` 通过（含 treefmt/statix/deadnix 质量门禁）
- ✅ flake-parts 架构：`flake.nixosConfigurations.omen` + `nix fmt` 统一格式化
- ✅ disko 声明式分区：`disko.nix` 接入，fileSystems 由 disko 生成（6 挂载点验证通过）
- ✅ `nixos build omen` 成功（含 firefox/chromium/kitty/网络诊断）
- ✅ home-manager 集成：用户 profile 含 fastfetch/btop/yazi/nvim
- ✅ fcitx5 i18n 块 + rime-ice override（系统层接管，HM 只管配置）
- ✅ 单仓库合并：home-manager 已并入 home/ 目录，消除跨仓库 path 引用
