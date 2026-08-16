# ============================================================
# games.nix —— 游戏（预留）
# 该放什么：Steam / Lutris / Heroic 等游戏平台及运行时
# 使用方式：home.packages = with pkgs; [ steam lutris ... ];
# 注意：32 位图形库已由系统层 hardware.nix 开启（enable32Bit）
# ============================================================
{ pkgs, ... }:

{
  # 预留：需要时在此添加游戏平台
  home.packages = with pkgs; [ ];
}
