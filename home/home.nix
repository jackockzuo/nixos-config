# ============================================================
# home.nix —— home-manager 主入口（NixOS 用户配置）
# 由 ~/nixos-config 通过 hm-ran input 引用本文件（见 nixos-config/flake.nix）
# 分层聚合：
#   core.nix    基础（用户/nix 客户端）
#   env.nix     环境变量（Wayland/输入法 sessionVariables）
#   desktop/    桌面环境配置（二进制由系统层安装，HM 管配置）
#   tools/      开发工具链（nix 管）
#   network/    网络配置（代理等）
# ============================================================
{ ... }:

{
  imports = [
    ./modules/core.nix
    ./modules/env.nix
    ./modules/desktop
    ./modules/tools
    ./modules/network
  ];

}
