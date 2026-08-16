# ============================================================
# proxy.nix —— 代理配置单一来源（全系统唯一修改点）
# 后端：fcclient（肥猫云）本地 HTTP 代理，端口 7892
#
# 🔴 换代理地址/端口/客户端 → 只改下方 options.proxy 的 default 值
#    所有消费方自动跟随，无需逐个改：
#      - modules/nix.nix                  → nix-daemon 下载走代理
#      - home/modules/network/proxy.nix   → 用户级环境变量 + fish 开关
#      - modules/security.nix             → sudo env_keep（放行列表，无需改地址）
# ============================================================
{ lib, ... }:

{
  options.proxy = {
    address = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:7892";
      description = "HTTP 代理完整地址（含协议与端口）";
    };
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "代理主机";
    };
    port = lib.mkOption {
      type = lib.types.str;
      default = "7892";
      description = "代理端口";
    };
    # 内网/本机/常用局域段放行（CIDR 由 curl/git 等客户端解析，无需 iptables）
    noProxy = lib.mkOption {
      type = lib.types.str;
      default = "localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12";
      description = "不走代理的内网/本机地址列表";
    };
  };
}
