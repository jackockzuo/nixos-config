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
        fc_backend: 'socks5://127.0.0.1:7892'
      }

      group {
        proxy {
          filter: name(fc_backend)
          policy: fixed(0)
        }
      }

      dns {
        upstream {
          alidns: 'udp://223.5.5.5:53'
          googledns: 'tcp+udp://8.8.8.8:53'
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
        pname(fcclient, fcclientCore, nix, nix-daemon, sshd, systemd-resolved) -> direct
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
}
