{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.proxy;
in
{
  options.proxy = {
    enable = lib.mkEnableOption "内核级透明代理劫持";

    address = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:7892";
      description = "后端代理地址 (fcclient)";
    };

    # 这里建议只留一个默认值，或者在 dae 配置里写死
    backendProcessName = lib.mkOption {
      type = lib.types.str;
      default = "fcclient";
      description = "后端代理工具主进程名";
    };
  };

  config = lib.mkIf cfg.enable {
    services.dae = {
      enable = true;

      # 显式指定包，防止被其他同名输入干扰
      package = pkgs.dae;

      # 确保资源包正确
      assets = with pkgs; [
        v2ray-geoip
        v2ray-domain-list-community
      ];

      disableTxChecksumIpGeneric = true;

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
          fc_backend: '${cfg.address}'
        }

        group {
          proxy {
            filter: name(fc_backend)
            policy: fixed
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
          # 直接在配置里写死要排除的进程名，防止变量注入导致的格式问题
          pname(fcclient, fcclientCore) -> direct
          
          # 排除维护工具
          pname(nix, nix-daemon, sshd, systemd-resolved) -> direct

          dip(geoip:private) -> direct
          dip(geoip:cn) -> direct
          domain(geosite:cn) -> direct

          fallback: proxy
        }
      '';
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };
}
