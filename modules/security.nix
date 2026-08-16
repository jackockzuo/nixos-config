# ============================================================
# security.nix —— 系统安全
# 该放什么：fail2ban / auditd / 安全加固 / 密钥管理服务
# 使用方式：services.fail2ban = { enable = true; ... }
# ============================================================
{ ... }:

{
  # ---- sudo 保留代理环境变量 ----
  # 方案 A（环境变量代理）的配套：sudo 默认 env_reset 会清空 http_proxy 等，
  # 导致 sudo curl/git 走直连（翻墙失效）。加入 env_keep 白名单让 sudo 应用同样走代理。
  # 代理地址单一来源：modules/proxy.nix（options.proxy）；
  # 变量注入在 home-manager 的 modules/network/proxy.nix（用户级）。
  security.sudo.extraConfig = ''
    Defaults env_keep += "http_proxy https_proxy all_proxy no_proxy"
  '';

  # 预留：需要时在此添加安全配置
}
