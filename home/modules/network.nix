# ============================================================
# proxy.nix —— 用户级代理应用层（环境变量 + fish 开关）
# 后端：fcclient（肥猫云）本地 HTTP 代理
#
# 🔴 代理地址单一来源：modules/proxy.nix 的 options.proxy（系统级），
#    经 flake.nix 的 home-manager.extraSpecialArgs 注入本模块（special arg `proxy`）
#    换端口/换客户端 → 改 modules/proxy.nix，本文件自动跟随
#
# 三层防御，防止"代理工具没开 → 全网断连"：
#   第 1 层（niri/config.kdl）：开机自动拉起 fcclient
#   第 2 层（本文件）：终端启动时探测端口，fcclient 没跑 → 自动清除代理变量
#   第 3 层（本文件）：fish 手动开关 proxy / noproxy
#
# 修改指南：
#   加内网放行   → 改 modules/proxy.nix 的 noProxy 默认值
#   临时直连     → fish 里敲 noproxy（本会话生效）
# ============================================================
{ lib, proxy, ... }:

let
  proxyAddr = proxy.address;
  proxyHost = proxy.host;
  proxyPort = proxy.port;
  inherit (proxy) noProxy;
in
{
  # ---- 全局代理环境变量（GUI 应用 + 新终端均继承）----
  # 大小写各一份：curl/npm 读大写，git 只认小写 http_proxy
  home.sessionVariables = {
    HTTP_PROXY = proxyAddr;
    HTTPS_PROXY = proxyAddr;
    ALL_PROXY = proxyAddr;
    NO_PROXY = noProxy;
    http_proxy = proxyAddr;
    https_proxy = proxyAddr;
    all_proxy = proxyAddr;
    no_proxy = noProxy;
  };

  # ---- 第 2 层：终端启动时探测代理端口，未运行则清除代理变量 ----
  # 依赖 nc（nixpkgs.netcat-openbsd 提供，无需额外安装，系统层已有）
  # 🔴 type -q nc 守卫（2026-08-18，Distrobox 容器报错修复）：
  #   宿主有 nc；容器内 Ubuntu 可能没装 netcat → 无守卫时报
  #   "Unknown command: nc"。守卫后：nc 不存在 → 跳过探测（直连模式）。
  programs.fish.interactiveShellInit = lib.mkAfter ''
    # 探测 fcclient 是否在监听；没跑就清掉代理变量，避免死代理断网
    if type -q nc
        if not nc -z -w1 ${proxyHost} ${proxyPort} 2>/dev/null
            set -e http_proxy https_proxy all_proxy
            set -e HTTP_PROXY HTTPS_PROXY ALL_PROXY
            echo "⚠️  fcclient 未运行，代理已禁用（直连模式）"
        end
    end
  '';

  # ---- 第 3 层：fish 快捷开关：proxy 开 / noproxy 关（仅当前会话）----
  xdg.configFile."fish/functions/proxy.fish".text = ''
    function proxy
        set -gx http_proxy  ${proxyAddr}
        set -gx https_proxy ${proxyAddr}
        set -gx all_proxy   ${proxyAddr}
        set -gx HTTP_PROXY  ${proxyAddr}
        set -gx HTTPS_PROXY ${proxyAddr}
        set -gx ALL_PROXY   ${proxyAddr}
        echo "🔌 代理已开启 → ${proxyAddr}"
    end
  '';

  xdg.configFile."fish/functions/noproxy.fish".text = ''
    function noproxy
        set -e http_proxy https_proxy all_proxy
        set -e HTTP_PROXY HTTPS_PROXY ALL_PROXY
        echo "🔌 代理已关闭（直连）"
    end
  '';
}
