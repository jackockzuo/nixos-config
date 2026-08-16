# ============================================================
# cpp.nix —— C/C++ LSP（clangd）
#   - clang-tools 提供 clangd（LSP 服务）+ clang-format + clang-tidy
#   - 🔴 neovim lspconfig 自动从 PATH 检测 clangd，无需任何 nvim 配置
# ============================================================
{ config, lib, pkgs, ... }:

{
  home.packages = lib.mkIf config.lsp.cpp.enable [
    pkgs.clang-tools # clangd + clang-format + clang-tidy
  ];
}
