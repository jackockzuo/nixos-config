# proxy.nix —— 透明代理（dae，主机专属，2026-09-05 恢复为 hosts/omen 剖面）
# 为什么在这：内核层接管所有应用（Chrome/CLI 零配置），geoip/geosite 判断国内直连，
#   无静态名单遗漏；fcclient 作后端（socks5://127.0.0.1:7892）只管非国内流量。
# 行为：fcclient 开 → 外网通；fcclient 关 → 国内直连照常、外网不可达（后端 down）。
# 共享层不引第三方（STANDARDS §0.5）；其他机器不 import 本文件。
# ============================================================
{ config, pkgs, ... }:

{
  services.dae = {
    enable = true;
    package = pkgs.dae;
    assets = with pkgs; [
      v2ray-geoip
      v2ray-domain-list-community
    ];
    disableTxChecksumIpGeneric = false; # 注：此 nixpkgs 快照该选项有 bug（getExe 参数错位），默认关；需要时手动 ExecStartPre 补
    openFirewall = {
      enable = true;
      port = 12345;
    };
    config = ''
      global {
        lan_interface: auto
        wan_interface: auto
        log_level: info
        allow_insecure: true
        auto_config_kernel_parameter: true
      }

      node {
        fc_backend: 'socks5://169.254.0.1:7892'
      }

      group {
        proxy {
          filter: name(fc_backend)
          policy: fixed(0)
        }
      }

      dns {
        # 缓存调优：乐观缓存(默认开)延长陈旧窗口 + 限容量防泄漏
        optimistic_cache: true
        optimistic_cache_ttl: 300
        max_cache_size: 4096

        upstream {
          alidns: 'udp://223.5.5.5:53'
          googledns: 'tcp://8.8.8.8:53'
        }
        routing {
          request {
            qname(geosite:cn) -> alidns
            fallback: googledns
          }
        }
      }

      routing {
        # 本机代理客户端与系统进程直连（防回环/防自拦截）
        # VPN/隧道工具必须直连（否则隧道流量被自己再代理=套娃）；其他需直连程序在此追加
        pname(fcclient, fcclientCore, nix, nix-daemon, sshd, systemd-resolved,
              openvpn, wireguard, wg-quick, tailscaled, tailscale, zerotier-one,
              chronyd, ntpd, syncthing) -> direct
        # 国内直连
        dip(geoip:private) -> direct
        dip(geoip:cn) -> direct
        domain(geosite:cn) -> direct
        # 其余走 fcclient
        fallback: proxy
      }
    '';
  };

  # 透明代理转发参数（仅本机启用 dae 时需要）
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # 后端 fcclient 在宿主机监听 *:7892：仅放行 dae 虚拟网卡(dae0)到达它，不暴露到局域网
  networking.firewall.interfaces.dae0 = {
    allowedTCPPorts = [ 7892 ];
    allowedUDPPorts = [ 7892 ];
  };

  # dae 的 L3 链路：宿主侧 dae0 需有 IPv4，daens(网关 169.254.0.1) 才能访问宿主机 fcclient。
  # 2026-09-05 实测：dae 只给 ns 侧配 169.254.0.11/32，宿主侧无地址 → 后端拨不通；
  # 手动 `ip addr add 169.254.0.1/30 dev dae0` 后宿主外网即通（google 204）。此处固化。
  systemd.services.dae-host-addr = {
    description = "Assign stable host address to dae0 (backend reachability)";
    wantedBy = [ "dae.service" ]; # 每次 dae 启动/重启都补配
    after = [ "dae.service" ];
    partOf = [ "dae.service" ]; # dae 重启重建 dae0 后地址会丢，须随 dae 一起重启补配
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = [ "PATH=/run/current-system/sw/bin:/usr/bin:/bin" ];
      ExecStart = pkgs.writeShellScript "dae-host-addr" ''
        set -e
        # 等 dae0 出现（dae 建网卡有竞态）
        i=0
        until ip link show dev dae0 >/dev/null 2>&1; do
          i=$((i+1))
          [ $i -ge 40 ] && exit 1
          sleep 0.5
        done
        ip addr show dev dae0 | grep -q 169.254.0.1 || ip addr add 169.254.0.1/30 dev dae0
      '';
    };
  };
}
