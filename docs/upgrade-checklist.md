# 升级体检单（NixOS / Home Manager 大版本升级前逐项核对）

> 目的：防止"构建成功但行为变化"的隐性破坏（构建期拦不住行为变更）。
> 原则：**只记录真实踩过/确证的破坏性变更**（事故驱动，见 STANDARDS 前言）；不预写预言性规则。

## 升级流程（顶部 checklist 逐项执行）

```bash
cd ~/nixos-config
nix flake update nixpkgs     # ① 只更新 nixpkgs（topgrade 自动链同款，不碰其他输入）
nix fmt && nix flake check   # ② 质量门禁
nix build .#nixosConfigurations.omen.config.system.build.toplevel  # ③ 预构建（不切换）
sudo nixos-rebuild switch --flake ~/nixos-config#omen              # ④ 切换（nr 别名自带快照）
```

- [ ] ③ 预构建通过（无新增 warning，STANDARDS §8）
- [ ] ④ 切换后**重启会话**（niri 配置/HM 激活的变更才生效）
- [ ] 实测：登录/解锁（hyprlock PAM）、输入法候选框（fcitx5 双通道）、毛玻璃（blur）、
      截图音效（screenshot-sound）、护眼（wlsunset 自动开启）
- [ ] 变更合规：STANDARDS §4 IM 双作用域两处同步（locale.nix + niri.nix）

## 历史破坏性变更档案（踩过才记）

### 2026-08：sops-install-secrets 需现场编译 → Go 模块下载失败
- **症状**：新 nixpkgs 下 `sops-install-secrets-go-modules.drv` 构建失败，
  `proxy.golang.org` TLS 握手超时（国内直连不稳定）。
- **原因**：刚更新的 nixpkgs 太新，cache.nixos.org 尚未生成该包缓存 → 现场编译 → 沙箱内 Go 下载不走代理。
- **应对**：等 1-2 天缓存生成后重试；或 `git checkout HEAD -- flake.lock` 回退。
- **教训**：`nix flake update` 后先 `nix build` 预检，别直接 switch。

### 2026-08：HM yazi shellWrapperName 默认值随 stateVersion 变化
- **症状**：`stateVersion < 26.05` 时 HM 默认 `shellWrapperName = "yy"`（弃用警告）。
- **处理**：显式 `shellWrapperName = "y"`（已在 yazi.nix 设置）。
- **核对项**：升级后检查 `nix flake check` 是否出现新弃用警告（STANDARDS §8 零容忍）。

### 2026-08：HM vscode 模块选项路径重命名
- **变更**：`programs.vscode.extensions/userSettings` → `programs.vscode.profiles.default.*`。
- **核对项**：升级后 grep 仓库是否有旧选项名残留。

## 固定护栏（不随版本变化）

- `home.stateVersion` **保持 24.05**（STANDARDS §3：首次使用值，不随 NixOS 版本升）
- `startAsUserService = true` + wantedBy（上游 #3172 竞态修复，**不要动**）
- IM 变量双作用域（STANDARDS §4）：locale.nix（系统层）+ niri.nix settings.environment
- nixd 补全 expr 引用 `nixosConfigurations.omen`（改 flake.nix 顶部 my.hostname 自动跟随）
