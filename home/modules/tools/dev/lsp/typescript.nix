# ============================================================
# typescript.nix —— TypeScript/JavaScript LSP（typescript-language-server）
#   - typescript-language-server：TS/JS 官方语言服务器（tsserver 封装）
#   - 已核对：当前 nixpkgs（rev 0e251e2）中存在 pkgs.typescript-language-server
#   - 🔴 运行时需要 nodejs 在 PATH 中才能启动 tsserver；
#     不在此默认添加 nodejs —— 用户多半已有（node 项目 nix develop 自带），
#     如确需独立 nodejs，取消下面注释：
#       # pkgs.nodejs
#   - 🔴 默认禁用：需要时在 lsp.nix 中把 config.lsp.typescript.enable 改为 true
# ============================================================
{ config, lib, pkgs, ... }:

{
  home.packages = lib.mkIf config.lsp.typescript.enable [
    pkgs.typescript-language-server
  ];
}
