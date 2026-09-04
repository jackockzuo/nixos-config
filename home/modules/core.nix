# ============================================================
# core.nix —— 基础层
# 职责：用户身份、nix 客户端配置
# ============================================================
{
  pkgs,
  lib,
  my,
  ...
}:

{
  # 用户（单一来源 flake.nix 顶部 my）
  home = {
    inherit (my) username homeDirectory stateVersion;
  };

  programs.home-manager.enable = true;

  # nix 客户端配置
  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # substituters 单一来源是系统层 modules/nix.nix（daemon 管理）
      connect-timeout = 10;
    };
  };

  # 客户端级 unfree 允许（nix profile add / nix-env 走 ~/.config/nixpkgs/config.nix）
  xdg.configFile."nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  xdg.configFile."nix/nix.conf".force = true;
}
