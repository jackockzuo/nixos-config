# network.nix —— 网络基础设置（平台无关）
# 职责：NetworkManager、防火墙、内核网络调优（BBR/fq）
# hostname/hostId 由 flake.nix hosts 清单注入 my（STANDARDS §0.2：机器标识禁止写死于此）
# ============================================================
{ my, ... }:

{
  networking = {
    hostName = my.hostname;
    inherit (my) hostId;
    networkmanager.enable = true;

    # 防火墙设置
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  # 内核网络调优（2026-09-03 自 modules/proxy.nix 迁入，通用无服务依赖）：
  #   BBR 拥塞控制 + fq qdisc 搭档 —— 高延迟/跨国拉取场景吞吐更优
  #   （旧 ip_forward/forwarding 随 dae 透明代理一并移除，仅代理场景需要）
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}
