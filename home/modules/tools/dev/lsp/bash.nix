# ============================================================
# bash.nix —— Bash LSP（bash-language-server）
#   - bash-language-server：bash 官方（vscode-bash 同源）语言服务器
#   - 已核对：当前 nixpkgs（rev 0e251e2）中存在 pkgs.bash-language-server
#   - 🔴 默认禁用：需要时在 lsp.nix 中把 config.lsp.bash.enable 改为 true
#   - 注：JSON/YAML/HTML/CSS 的 LSP 在 web.nix（vscode-langservers-extracted）
# ============================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = lib.mkIf config.lsp.bash.enable [
    pkgs.bash-language-server
  ];
}
