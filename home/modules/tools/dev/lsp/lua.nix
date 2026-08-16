# ============================================================
# lua.nix —— Lua LSP（lua-language-server）
#   - lua-language-server：LuaLS 官方，社区主流 Lua 语言服务器
#   - 已核对：当前 nixpkgs（rev 0e251e2）中存在 pkgs.lua-language-server
#   - 🔴 默认禁用：需要时在 lsp.nix 中把 config.lsp.lua.enable 改为 true
# ============================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = lib.mkIf config.lsp.lua.enable [
    pkgs.lua-language-server
  ];
}
