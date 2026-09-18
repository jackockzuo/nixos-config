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
  # 身份（username/homeDirectory）由系统层 users.users 自动派生
  # （HM 作为 NixOS 模块时 nixos/common.nix 会按 users.users.<name> 设置）；
  # 此处只保留 HM 自己的 stateVersion（首次使用值，勿随版本升，STANDARDS §3）
  home.stateVersion = my.stateVersion;

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
      # 与系统层 connect-timeout 保持一致
      connect-timeout = 5;
    };
  };

  # 客户端级 unfree 允许（nix profile add / nix-env 走 ~/.config/nixpkgs/config.nix）
  xdg.configFile."nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  xdg.configFile."nix/nix.conf".force = true;
}
