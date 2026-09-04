# home.nix —— home-manager 主入口（NixOS 用户配置）
# ============================================================
{ ... }:

{
  imports = [
    ./modules/core.nix
    ./modules/env.nix
    ./modules/desktop
    ./modules/tools

  ];
}
