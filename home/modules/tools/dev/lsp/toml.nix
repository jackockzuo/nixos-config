# ============================================================
# toml.nix —— TOML LSP（taplo）
#   - taplo：Rust 编写的 TOML 语言服务器 + 格式化（taplo fmt）
#   - 已核对：当前 nixpkgs（rev 0e251e2）中存在 pkgs.taplo
#   - 🔴 默认禁用：需要时在 lsp.nix 中把 config.lsp.toml.enable 改为 true
# ============================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = lib.mkIf config.lsp.toml.enable [
    pkgs.taplo
  ];
}
