# ============================================================
# system.nix —— 系统基础
# 职责：stateVersion（迁移安全阀）、unfree 放行
# 修改：NixOS 大版本升级时更新 stateVersion → 改这里
# 注意：秘密（GitHub token/密码）由 sops-nix 管理（modules/secrets.nix）
# ============================================================
_:

{
  # NixOS stateVersion（首次安装值，勿随大版本升）；HM 的 stateVersion 在 flake.nix my.stateVersion
  system.stateVersion = "25.05";

  # 允许 unfree（nvidia 驱动、chrome 等）
  # allowUnfree 有三个作用域（各自机制不同，非重复定义，STANDARDS §0.2 唯一来源指"同一作用域内"）：
  #   ① 本处 = 系统 nixpkgs.config（NixOS 求值）
  #   ② flake.nix perSystem = devShell 用的 pkgs
  #   ③ home/modules/core.nix = 用户 nix 客户端（nix profile/nix-env）
  nixpkgs.config.allowUnfree = true;
}
