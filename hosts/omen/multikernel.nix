# ============================================================
# multikernel.nix —— 多内核（当前禁用占位，2026-09-05）
# 状态：暂停启用 —— 用户先验证其它功能；等网络/宽带环境再启用。
# 启用方法：把本文件放进 hosts/omen/default.nix 的 imports，或把下方
#   specialisation 块粘回 modules/boot.nix（并给基础 kernelPackages 加
#   lib.mkDefault 以允许覆盖）。
# 背景：cachyos 默认内核 + latest/lts 备用内核；
#       ⚠️ 非 cachyos 内核须用对应官方 nvidia 驱动（nvidia_cachyos 仅配 cachyos）。
#       nix 下载已改直连（官方源 2.9MB/s），构建已无网络障碍。
# ============================================================
# {
#   pkgs,
#   lib,
#   ...
# }:
#
# specialisation = {
#   latest.configuration = {
#     boot.kernelPackages = pkgs.linuxPackages_latest; # 主线尝鲜
#     hardware.nvidia.package = lib.mkForce pkgs.linuxPackages_latest.nvidiaPackages.stable;
#   };
#   lts.configuration = {
#     boot.kernelPackages = pkgs.linuxPackages_6_12; # 稳定兜底
#     hardware.nvidia.package = lib.mkForce pkgs.linuxPackages_6_12.nvidiaPackages.stable;
#   };
# };
