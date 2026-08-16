# ============================================================
# typst.nix —— Typst LSP（tinymist）
#   - tinymist：Typst 官方社区维护，现代且活跃 —— 默认选它
#   - 🔴 已核对：当前 nixpkgs 中不存在 typst-lsp 包（已移除），
#     只有 tinymist 可用；未来若 nixpkgs 恢复 typst-lsp 也可换回
#   - 构建 .typ 文件还需编译器 pkgs.typst（按需取消注释）：
#       # pkgs.typst
# ============================================================
{ config, lib, pkgs, ... }:

{
  home.packages = lib.mkIf config.lsp.typst.enable [
    pkgs.tinymist
  ];
}
