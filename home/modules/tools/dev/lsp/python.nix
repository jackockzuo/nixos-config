# ============================================================
# python.nix —— Python LSP（pyright）
#   - pyright：微软官方 Python 类型检查 + LSP（纯 Node 实现，无 venv 依赖）
#   - 已核对：当前 nixpkgs（rev 0e251e2）中存在 pkgs.pyright
#   - 🔴 默认禁用：需要时在 lsp.nix 中把 config.lsp.python.enable 改为 true
# ============================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = lib.mkIf config.lsp.python.enable [
    pkgs.pyright # Python 类型检查 + LSP
  ];
}
