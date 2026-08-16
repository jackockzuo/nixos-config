# ============================================================
# go.nix —— Go LSP（gopls）
#   - gopls：Go 官方语言服务器（golang.org/x/tools 官方维护）
#   - 已核对：当前 nixpkgs（rev 0e251e2）中存在 pkgs.gopls
#   - 🔴 运行时需要 go 在 PATH 中（跳转/编译诊断依赖 go 工具链）；
#     不在此默认添加 go —— Go 项目通常用 nix develop 提供，
#     如确需独立 go 工具链，取消下面注释：
#       # pkgs.go
#   - 🔴 默认禁用：需要时在 lsp.nix 中把 config.lsp.go.enable 改为 true
# ============================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = lib.mkIf config.lsp.go.enable [
    pkgs.gopls
  ];
}
