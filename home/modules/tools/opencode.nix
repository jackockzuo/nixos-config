# ============================================================
# opencode.nix —— AI 编码助手（opencode）
# 职责：安装 opencode CLI（AI 驱动的终端编码代理）
# 修改：升级/换版本 → 改这里（包版本由 nixpkgs 锁定）
# 关联：neovim.nix（同为开发工具）、dev.nix（预留：语言工具链）
# ============================================================
{ pkgs, ... }:

{
  # opencode：终端内的 AI 编码代理（与 Claude Code 同类）
  home.packages = with pkgs; [
    opencode
  ];
}
