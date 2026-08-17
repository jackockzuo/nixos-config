# 疑难杂症：niri 登录失败（密码正确却报错 + 进不去桌面）

- 日期：2026-08-17
- 状态：✅ 已解决（含遗留事项）
- 影响范围：整个桌面无法登录（greetd/DMS 登录界面正常显示，密码始终被拒；niri 无法启动）
- 涉及文件：
  - `modules/users.nix`（密码机制：hashedPasswordFile → 临时直写哈希）
  - `modules/hardware.nix`（会话变量 + nvidia 配置澄清）
  - `modules/desktop.nix`（greetd initial_session 移除）
  - `secrets/secrets.yaml`（sops 秘密，未改动，但疑似问题源头）

---

## 症状

1. 登录界面（DMS greeter）输入正确密码 → 提示密码错误（PAM AUTH_ERR）；
2. 无法进入 niri 桌面；`su` / TTY 登录同样失败；
3. 系统日志反复出现 `pam_unix(greetd:auth): authentication failure; user=ran`。

## 环境

- 机器：HP OMEN 16-wf0xxx（omen），NVIDIA RTX 4060 混合显卡（prime offload），Intel iGPU 为主
- NixOS：26.11.20260813（nixos-unstable），kernel `linuxPackages_latest`（构建版本 7.1.8），nvidia 595.91.07
- 桌面：niri + DMS（DankMaterialShell）greeter，greetd 启动
- 密码管理：sops-nix `hashedPasswordFile`（`neededForUsers` → `/run/secrets-for-users`），`mutableUsers = false`
- 时间线背景：8-16 晚完成"密码迁移 sops"（commit 34b1c00），此后一直无法登录；8-17 凌晨两次 rebuild（含未提交的试验改动）仍未解决。

## 排查过程（时间线 + 关键证据）

### 1. 确认 PAM 链路正常
- `/etc/pam.d/greetd`、`login` 均为标准 NixOS 配置（`pam_unix` + `login` substack）→ PAM 无问题。

### 2. 解密 sops 秘密，验证哈希内容
- 利用系统自带 `sops-install-secrets`（构造 manifest 指向可读输出路径）解密 `user-password`：
  ```
  $y$j9T$HYOsuolSk8zMUrJBaeiDP0$7qQkf3M0GpwAWT.qUIeGMO.1rhPlGWby3i/bM9PwT29
  ```
- 用 `perl crypt("ran", hash) == hash` 验证：**该哈希明文就是 `ran`**（初始密码）。

### 3. 真机验证 `su ran` 输入 `ran` → 仍失败
- 说明 `/etc/shadow` 中 ran 的哈希 ≠ 秘密文件内容（尽管 `/run/secrets-for-users/user-password` 文件存在、大小 73 字节与哈希一致）。

### 4. 沙箱复现激活脚本，证明脚本正确
- 将 `update-users-groups.pl` 改路径后跑沙箱（伪造 passwd/group/shadow + 已知哈希文件）→ **输出 shadow 与 crypt 验证通过**。
- 结论：**断点在 sops-install-secrets 解密写文件那一环**（`/run/secrets-for-users` 实际内容与预期不符），激活脚本本身无问题。

### 5. 显卡真相
- `lsmod`：nouveau 加载、nvidia 模块未加载；但当前 generation 的 kernel-modules（7.1.8）里 nvidia 模块齐全。
- 排查 nixpkgs 源码（`nixos/modules/hardware/video/nvidia.nix`）：
  - `hardware.nvidia.enabled` 是**只读选项**，由 `services.xserver.videoDrivers` 含 `"nvidia"` 自动推导；
  - 配置一直有效，但**机器实际用旧内核（6.18）旧 generation 引导**（从未重启到新 build），所以 nouveau 在跑。
- 教训：**内核/驱动类问题先确认 `uname -r` 与 `/run/current-system` 是否一致**。

### 6. 构建报错两轮（我犯的错）
- `hardware.nvidia.enable = true` → **选项不存在**（本 nixpkgs 是 `enabled`）；
- `hardware.nvidia.enabled = true` → **只读选项重复设置**（模块自己已设置）。
- 最终确认：该选项**无需也不能手动设置**，删除即可。

### 7. live ISO / nixos-enter 环境坑
- chroot 内 nix-daemon 不运行 → `nixos-rebuild` 报 `cannot connect to socket` → 需手动 `nix-daemon &`；
- chroot 内 GRUB/dbus 步骤失败（os-prober 扫 USB 报错、无 dbus socket）→ build 成功但 switch 激活失败（/etc/shadow 未写）；
- 解决方案：单独执行 `update-users-groups.pl`（users 激活步骤）写入密码，GRUB 实际已由失败的 switch 更新好（含新 generation 53）。

## 根因分析

| # | 问题 | 直接原因 | 深层原因 |
|---|---|---|---|
| 1 | 密码永远被拒 | `/etc/shadow` 哈希与用户输入不匹配 | **sops→/run 文件内容链损坏**（文件存在但内容 ≠ sops 里的哈希）；`mutableUsers=false` 下每次 rebuild 用坏内容重写 shadow，登录自 sops 迁移起就一直是坏的 |
| 2 | niri 起不来 | niri EGL 初始化崩溃 | 会话变量强制 `GBM_BACKEND=nvidia-drm`，但运行内核（旧 6.18）无 nvidia 模块、nouveau 在跑 → 用户态 nvidia 栈找不到内核驱动 |
| 3 | 登录流程混乱 | greetd 先跑 initial_session（自动登录 niri），崩溃后回落 greeter | 未提交的 `initial_session` 试验改动与既有"greeter 登录"设计冲突 |

## 修复方案

| 文件 | 改动 | 说明 |
|---|---|---|
| `modules/users.nix` | `hashedPasswordFile` → `hashedPassword = "<已验证的 ran 哈希>"` | ⚠️ **临时应急**：绕过损坏的 sops 文件链，哈希直写进 users-groups.json（构建期即固定，激活不读文件，沙箱验证必生效）。**违反 STANDARDS §0.6（秘密明文进仓库），属遗留债，见下** |
| `modules/desktop.nix` | 删除 `initial_session` | 恢复 DMS greeter 登录流程 |
| `modules/hardware.nix` | 不新增开关；会话变量格式化 | 确认 `enabled` 为只读自动推导，无需写；保留原有 prime/offload 配置 |

验证方式：rebuild 后 `su ran -c whoami` 输入 `ran` 通过；重启后 greeter 登录成功进入 niri。

## 恢复流程（live ISO 可复用）

```bash
# 1. 挂载（UUID 来自 hardware-configuration.nix）
sudo mkdir -p /mnt
sudo mount -o subvol=@ /dev/disk/by-uuid/42701c28-c857-4f68-883a-125c1e985b33 /mnt
sudo mkdir -p /mnt/nix /mnt/home /mnt/boot
sudo mount -o subvol=@nix  /dev/disk/by-uuid/42701c28-c857-4f68-883a-125c1e985b33 /mnt/nix
sudo mount -o subvol=@home /dev/disk/by-uuid/42701c28-c857-4f68-883a-125c1e985b33 /mnt/home
sudo mount /dev/disk/by-uuid/71C7-34C8 /mnt/boot

# 2. 进入系统
sudo nixos-enter --root /mnt
nix-daemon &        # 🔴 chroot 内必须手动起 daemon

# 3. 重建
cd /home/ran/nixos-config
nixos-rebuild switch --flake .#omen 2>&1 | tee /home/ran/nixos-config/build-error.log

# 4. 若 switch 激活失败（chroot 环境 GRUB/dbus 报错属正常），补写密码：
bash /home/ran/nixos-config/docs/troubleshooting/fix-password.sh

# 5. 验证 → 退出 → 重启
su ran -c whoami     # 输入 ran
exit && sudo reboot
```

> 一键救援脚本：[fix-password.sh](./fix-password.sh)（自动判断在 chroot 内还是 live ISO，挂载→写密码→验证）

## 经验教训（防再犯）

1. **密码只走一条路，改完必须本地验证**：`su <user> -c whoami` 输密码确认，别直接重启；
2. **`passwd` 运行时改密码不持久**：`mutableUsers=false` 下下次 rebuild 必被覆盖；
3. **未提交的试验改动禁止直接 switch**：先 commit 或分支，出问题可回退（本次 initial_session、显卡会话变量都是未提交改动）；
4. **rebuild 前验证三步**：`nix flake check` → `nixos-rebuild build`（拦选项名错误，本次 enable/enabled 就是这类）→ `nixos-rebuild dry-activate`；
5. **显卡/内核类问题先确认引导状态**：`uname -r` vs `/run/current-system` 是否一致；黑屏回滚用 GRUB 旧 generation；
6. **live ISO / nixos-enter 里**：手动 `nix-daemon &`；GRUB/dbus 步骤失败是环境限制，别当成配置错误；
7. **选项名以 nixpkgs 源码为准**（`nixos/modules/hardware/video/nvidia.nix`），别凭记忆。

## 遗留事项（TODO）

- [ ] **修复 sops 密码链根因**：排查 `sops-install-secrets` 写入 `/run/secrets-for-users` 内容为何与 secrets.yaml 不符（疑点：neededForUsers 秘密写文件环节；可先在真机上 `sudo cat /run/secrets-for-users/user-password` 与解密值比对）；
- [ ] **恢复 sops 密码管理**：确认根因后，`users.nix` 的 `hashedPassword` 改回 `hashedPasswordFile = config.sops.secrets.user-password.path`，消除明文哈希（STANDARDS §0.6）；
- [ ] **root 密码**：当前仍走 sops `hashedPasswordFile`，链若同样损坏 root 登录会失败；登录后 `sudo nixos-rebuild switch` 在真机环境收尾可恢复（若仍失败则同样处理）；
- [ ] **验证 nvidia 驱动状态**：重启到新 generation（内核 7.1.8）后确认 `lsmod | grep nvidia`、`nvidia-smi` 正常、niri 无崩溃。
