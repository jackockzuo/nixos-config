# ============================================================
# home.nix —— home-manager 主入口（NixOS 用户配置）
# 已被 flake.nix 以 home-manager.users.ran.imports = [ ./home/home.nix ] 引用
# 分层聚合（目录 ≤2 层）：
#   core.nix    基础（用户/nix 客户端）
#   env.nix     环境变量（会话变量，IM 单一来源见系统层 locale.nix）
#   desktop/    桌面环境配置（二进制由系统层安装，HM 管配置）
#   tools/      开发工具链（nix 管，扁平一层）
#   network.nix 网络配置（代理 / fish 开关）
# ============================================================
{ ... }:

{
  imports = [
    ./modules/core.nix
    ./modules/env.nix
    ./modules/desktop
    ./modules/tools
    ./modules/network.nix
  ];
}
