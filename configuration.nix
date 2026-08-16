# ============================================================
# configuration.nix —— 系统配置聚合入口（已按关注点拆分到 modules/）
# 职责：只做 imports，不含任何具体配置
# 结构：见 modules/ 目录（一文件一关注点）
#   可用模块：boot / hardware / network / users / desktop / services
#             locale / fonts / nix / packages / virtualisation
#   预留模块：firewall / vpn / databases / media-server / syncthing
#             printing / security
# 修改：具体配置改 modules/<关注点>.nix，这里不再新增内容
# ============================================================
{
  imports = [
    ./modules
  ];
}
