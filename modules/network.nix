# network.nix —— 网络基础设置
# 职责：主机名、NetworkManager、内核网络调优
# ============================================================
{ my, ... }:

{
  networking = {
    hostName = my.hostname;
    hostId = "007f0200";
    networkmanager.enable = true;

    # 防火墙设置
    firewall = {
      enable = true;
      # dae 的透明代理在内核层处理，通常不需要额外开放端口
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

}
