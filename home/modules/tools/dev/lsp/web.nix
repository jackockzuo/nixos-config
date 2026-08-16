# ============================================================
# web.nix —— Web 格式 LSP（vscode-langservers-extracted）
#   - vscode-langservers-extracted：从 vscode 中提取的官方语言服务器合集
#   - 覆盖：JSON（jsonls）+ YAML（yaml-language-server）+ HTML + CSS
#   - 已核对：当前 nixpkgs（rev 0e251e2）中存在 pkgs.vscode-langservers-extracted
#   - 🔴 默认禁用：需要时在 lsp.nix 中把 config.lsp.web.enable 改为 true
# ============================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = lib.mkIf config.lsp.web.enable [
    pkgs.vscode-langservers-extracted # jsonls + yaml-language-server + html + css
  ];
}
