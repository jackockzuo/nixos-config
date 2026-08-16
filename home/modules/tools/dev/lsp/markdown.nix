# ============================================================
# markdown.nix —— Markdown LSP（marksman）
#   - marksman：Rust 编写的 Markdown 语言服务器（补全/引用/目录跳转）
#   - 已核对：当前 nixpkgs（rev 0e251e2）中存在 pkgs.marksman
#   - 🔴 默认禁用：需要时在 lsp.nix 中把 config.lsp.markdown.enable 改为 true
# ============================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = lib.mkIf config.lsp.markdown.enable [
    pkgs.marksman
  ];
}
