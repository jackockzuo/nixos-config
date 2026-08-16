# ============================================================
# system.nix —— 系统基础
# 职责：stateVersion（迁移安全阀）、unfree 放行
# 修改：NixOS 大版本升级时更新 stateVersion → 改这里
# 注意：秘密（GitHub token/密码）由 sops-nix 管理（modules/secrets.nix）
# ============================================================
_:

{
  system.stateVersion = "25.05";

  # 允许 unfree（nvidia 驱动、chrome 等）
  nixpkgs.config.allowUnfree = true;
}
