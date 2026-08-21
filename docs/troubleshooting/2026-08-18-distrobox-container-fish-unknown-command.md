# 疑难杂症：Distrobox 容器内 fish 报 "Unknown command"（宿主工具链失效）

- 日期：2026-08-18
- 状态：✅ 已解决
- 影响范围：Distrobox 容器（ubuntu/math）内打开 fish 时报一堆 `Unknown command: atuin/fzf/zoxide/...` 与 `nc: Unknown command`，终端启动噪音大；容器内无宿主工具却执行其集成脚本
- 涉及文件：
  - `home/modules/tools/terminal/atuin.nix`（enableFishIntegration → type -q 守卫）
  - `home/modules/tools/terminal/zoxide.nix`（同上）
  - `home/modules/tools/terminal/fzf.nix`（同上）
  - `home/modules/tools/terminal/starship.nix`（同上）
  - `home/modules/tools/terminal/fish.nix`（fastfetch 加 type -q 守卫）
  - `home/modules/tools/dev/direnv.nix`（同上）
  - `home/modules/network/proxy.nix`（nc 探测加 type -q nc 守卫）

---

## 症状

- 在 Distrobox 容器（如 `distrobox enter math`）里打开 fish，终端报错：
  ```
  Unknown command: atuin
  Unknown command: nc
  return: Error: return outside of function definition
  ```
- stdin 为 tty 时报错，`fish -i </dev/null`（stdin 非 tty）不触发 → 排查时必须用 PTY 复现；非 tty 下 `status is-interactive` 为 false，集成脚本整段跳过，容易误判"容器里没问题"。

## 环境

- 宿主：NixOS omen，fish ≥ 4.x（nixpkgs 携带）
- 容器：`distrobox enter math`（Ubuntu 22.04，fish 3.3.1）
- Distrobox 挂载 $HOME 与 /nix → 容器内 fish 自动加载宿主的 `~/.config/fish/config.fish`（HM 生成的 store symlink 也在 /nix 内、可读）

## 排查过程（关键证据）

1. 复现（PTY，非 tty 无效）：
   ```
   distrobox enter math --additional-flags "--env XDG_CONFIG_HOME=..." -- fish
   ```
   → 报 `Unknown command: atuin`、`nc: Unknown command`；fish 3.3.1 下 fzf 旧语法还触发 `return outside of function definition`。

2. 容器内 `type -q` 实测（fish 3.3.1 支持）：
   ```
   atuin/fzf/zoxide/starship/direnv/fastfetch: missing   ← 全部不在容器 PATH
   nc: PRESENT                                            ← 唯一存在
   ```
   证明根因是"工具不存在却执行其集成脚本"，而非脚本本身错。

3. 生成产物检查：`nix build .#nixosConfigurations.omen.config.home-manager.users.ran.home.activationPackage` → 展开 `home-files/.config/fish/config.fish`，确认修复后的守卫序列正确落盘。

## 根因分析

- **直接原因**：HM 的 `programs.<tool>.enableFishIntegration = true` 会生成一条**无条件**执行 store 内绝对路径集成的脚本（如 `/nix/store/...-atuin/bin/atuin init fish | source`）。/nix 被 Distrobox 挂载进容器，脚本**找得到**，但容器里没有把该工具加进 PATH → `Unknown command`。
- **深层原因**：HM 的集成假设"工具在 PATH 中"是成立的（宿主成立），但跨挂载边界（容器读宿主 $HOME + /nix）时 PATH 不共享，该假设破裂。
- **为什么之前没发现**：宿主 fish 启动正常、非 tty 复现不触发，只有真正进容器交互 shell 才暴露。

## 修复方案

统一改法：关闭 HM 无条件集成（`enableFishIntegration = false`），在 `programs.fish.interactiveShellInit` 用 `lib.mkAfter` 追加 **`type -q <tool>` 守卫**后再执行等价集成：

```fish
if type -q atuin
    atuin init fish | source
end
```

- 守卫选 **`type -q`** 而非 `command -q`：container 内 fish 是 3.3.1，`command -q` 是 fish 3.4+ 才有，`type -q` 全版本兼容。
- `atuin init fish | source` / `fzf --fish | source` / `zoxide init fish | source` / `direnv hook fish | source` / `starship init fish | source` 运行时生成与 HM store 文件**同款**集成脚本（含各工具自身版本适配，宿主行为不变）。
- nc 探测同理包一层 `if type -q nc`：nc 缺失（部分容器镜像不带 netcat）→ 跳过探测（直连模式，不再误报）。
- fastfetch（写在 `fish.nix` 的 interactiveShellInit 内）包 `type -q fastfetch`，保留原有 FASTFETCH_RUN_ONCE 去重。

验证：

```bash
# 1. 宿主侧：7 个工具全部 PRESENT，守卫放行，starship 提示符正常渲染
# 2. 容器侧（math，fish 3.3.1）：atuin/fzf/zoxide/starship/direnv/fastfetch missing
#    → 静默跳过，无任何 Unknown command 输出；nc PRESENT 探测照常
# 3. nix fmt + nix flake check 全绿
```

## 恢复流程（无需）

纯配置改动，无数据风险。直接 `nixos-rebuild switch --flake .#omen` 部署即可。

## 经验教训（防再犯）

1. **跨挂载边界的 HM 集成脚本一律要 `type -q` 守卫**：凡工具来自 home.packages / programs.* 且集成脚本会被容器挂载的 $HOME 加载，都要防"脚本在、工具不在"；
2. **容器类复现必须用 PTY**（交互 shell）：非 tty 下 `status is-interactive` 为 false，整个 interactiveShellInit 被跳过，无法复现也等于"假验证通过"；
3. **守卫语法向下兼容**：容器内 fish 版本可能落后（3.3.1），用 `type -q` 不用 `command -q`；
4. 修复后双端验证：宿主（放行 + 功能不变）+ 容器（跳过 + 零报错）都要测。

## 遗留事项（TODO）

- [ ] `nixos-rebuild switch` 部署该 generation 后，容器内再验证一次（本记录验证基于 `nix build ...activationPackage` 的展开产物，未改动线上 config）。