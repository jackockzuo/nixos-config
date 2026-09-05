# rEFInd + Minimalist 引导迁移（2026-09-05）REF:2026-09-05-refind

## 目标与状态
- 引导器从 GRUB 换成 **rEFInd**（`hosts/omen/refind.nix`），主题 = Minimalist
  （evanpurkhiser/rEFInd-minimal，vendor 于 `assets/refind-minimal/`，icons 含 os_nixos/os_arch/os_win）。
- 主题经 tmpfiles `C! /boot/EFI/refind/themes/refind-minimal <- store` 每次开机拷贝。
- NixOS refind 模块写 `/boot/EFI/refind/` + NVRAM 项（`canTouchEfiVariables`）。
- 保留旧 GRUB：`/boot/EFI/NixOS-boot/` 文件与固件项 `Boot0002 NixOS-boot` **不删除** = 回退锚点。

## 迁移前现场备份（assets/grub-backup/）
- `grub.cfg`：`/boot/grub/grub.cfg` 副本
- `efibootmgr-before.txt`：固件启动项快照（BootOrder: 0002 NixOS-boot, 0003 Windows…）

## 多系统/镜像处理
- 共享层 `modules/boot.nix` 保持 GRUB 默认（其它主机照旧）；仅 omen 用 `mkForce false` 关 GRUB 并启用 rEFInd。
- rEFInd `scanfor internal,external,optical,biosexternal`：Windows（另一 NVMe ESP）会被自动发现。
- 图标：主题自带 os_nixos/os_arch/os_win/…；多发行版镜像出现时自动套用，找不到回退默认图标。

## 验证清单（切换后）
1. `efibootmgr -v` 出现 rEFInd 项（含 `\EFI\refind\refind_x64.efi`）且 BootOrder 置前。
2. `ls /boot/EFI/refind/`：refind_x64.efi + refind.conf；`themes/refind-minimal/` 已复制。
3. `head /boot/EFI/refind/refind.conf` 含 `include themes/refind-minimal/theme.conf`。
4. 重启 → Minimalist 界面显示 NixOS + Windows（若 NixOS 图标为默认 linux 属正常，可用 icons 映射微调）。

## 回退（重要）
- 配置回退：从 `hosts/omen/default.nix` imports 删 `./refind.nix` → `nr`（GRUB 模块重新接管）。
- 固件应急：开机引导菜单选旧项 `NixOS-boot`（GRUB，仍在）。
- NVRAM 清理（可选）：`sudo efibootmgr -b <refind编号> -B`。
