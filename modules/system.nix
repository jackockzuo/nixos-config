# ============================================================
# system.nix —— 系统基础
# 职责：stateVersion（迁移安全阀）、unfree 放行
# 修改：NixOS 大版本升级时更新 stateVersion → 改这里
# 注意：GitHub token 由 flake.nix 的 secrets 输入注入（不在此文件）
# ============================================================
{ ... }:

{
  # 🔴 私有配置（GitHub token 等）经 flake.nix 的 secrets path 输入引入
  # （见 flake.nix inputs.secrets，指向仓库外 ~/Documents/nix-secrets/）。
  # 仓库外路径不受 git 追踪，token 永不进 git 历史。
  system.stateVersion = "25.05";

  # 允许 unfree（nvidia 驱动、chrome 等）
  nixpkgs.config.allowUnfree = true;
}
