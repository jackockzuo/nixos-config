# ============================================================
# network.nix —— 网络
# 职责：主机名、NetworkManager、内核网络调优
# 修改：改主机名/换网络后端 → 改这里
# 注意：代理地址单一来源 modules/proxy.nix，用户级应用见 home/modules/network.nix
# ============================================================
_:

{
  # ============ 主机与网络 ============
  networking.hostName = "omen";
  networking.networkmanager.enable = true;

  # ============ 内核网络调优（BBR 拥塞控制）============
  # 🎯 [OMEN] 本机独有：代理/跨国拉取数据的场景下高延迟网络吞吐更优；
  #    fq qdisc 是 BBR 的搭档；不需要可整块删除
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    # TCP 缓冲区上限：大流量下载/上传场景防丢吞吐
    "net.core.rmem_max" = 2500000;
    "net.core.wmem_max" = 2500000;
  };
}
