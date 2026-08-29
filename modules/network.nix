# ============================================================
# network.nix —— 网络
# 职责：主机名、NetworkManager、内核网络调优
# 修改：改主机名 → 改 flake.nix 顶部 my.hostname（单一来源，本文件自动跟随）
# 注意：代理地址单一来源 modules/proxy.nix，用户级应用见 home/modules/network.nix
# ============================================================
{ my, ... }:

{
  # ============ 主机与网络 ============
  networking = {
    hostName = my.hostname;
    # 🔴 hostId 显式固定（借鉴优秀实践）：NixOS 默认从 machine-id 隐式派生，
    #    重装/迁移后变化会影响 snapper 等工具的一致性；固定当前值保证快照体系稳定
    hostId = "007f0200";
    networkmanager.enable = true;

    # ====== 防火墙（显式声明，不靠隐式默认）=====
    # fcclient 代理（7892）是本地回环，不经过防火墙 ✓
    # podman 默认 slirp4netns 用户态网络，容器端口不经防火墙 ✓
    # 将来要对外提供服务（局域网/公网）→ 在这里加 allowedTCPPorts/UDPPorts
    firewall = {
      enable = true;
      allowedTCPPorts = [ ]; # 需要时在此开放（如局域网服务）
      allowedUDPPorts = [ ];
    };
  };

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
