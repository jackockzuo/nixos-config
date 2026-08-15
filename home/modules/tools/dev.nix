# ============================================================
# dev.nix —— 开发语言/数据库客户端（预留）
# 该放什么：nodejs / rustup / go / python venv / 数据库 GUI 客户端
# 使用方式：home.packages = with pkgs; [ nodejs_22 ... ];
# 注意：常驻数据库服务（PostgreSQL 等）放 nixos-config/modules/databases.nix
# ============================================================
{ pkgs, ... }:

{
  # 预留：需要时在此添加开发工具链
  home.packages = with pkgs; [ ];
}
