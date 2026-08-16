# ============================================================
# network.nix —— 网络
# 职责：主机名、NetworkManager
# 修改：改主机名/换网络后端 → 改这里
# 注意：代理地址单一来源 modules/proxy.nix，用户级应用见 home/modules/network/proxy.nix
# ============================================================
_:

{
  # ============ 主机与网络 ============
  networking.hostName = "omen";
  networking.networkmanager.enable = true;
}
