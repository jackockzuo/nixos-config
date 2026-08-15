# ============================================================
# network.nix —— 网络
# 职责：主机名、NetworkManager
# 修改：改主机名/换网络后端 → 改这里
# 注意：代理是用户级配置（home-manager/network/proxy.nix）
# ============================================================
{ ... }:

{
  # ============ 主机与网络 ============
  networking.hostName = "omen";
  networking.networkmanager.enable = true;
}
