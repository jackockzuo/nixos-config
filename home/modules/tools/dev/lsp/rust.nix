# ============================================================
# rust.nix —— Rust LSP（rust-analyzer）
#   - rust-analyzer：rustup 组件或 nix 包，此处用 nix 包
#   - 🔴 rust-analyzer 需要 rustc/rustfmt 在 PATH 中才能完整工作
#     （跳转标准库、格式化）如需完整 Rust 工具链，取消下面注释：
#       # pkgs.rustc
#       # pkgs.rustfmt
# ============================================================
{ config, lib, pkgs, ... }:

{
  home.packages = lib.mkIf config.lsp.rust.enable [
    pkgs.rust-analyzer
  ];
}
