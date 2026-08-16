# ============================================================
# docker.nix —— Dockerfile LSP（dockerfile-language-server-nodejs）
#   - dockerfile-language-server-nodejs：Docker 官方 Dockerfile 语言服务器
#   - 已核对：当前 nixpkgs（rev 0e251e2）中存在 pkgs.dockerfile-language-server-nodejs
#   - 🔴 运行时需要 nodejs 在 PATH 中；不在此默认添加 nodejs
#     （理由同 typescript.nix：用户多半已有，需要时取消下面注释）：
#       # pkgs.nodejs
#   - 🔴 默认禁用：需要时在 lsp.nix 中把 config.lsp.docker.enable 改为 true
# ============================================================
{ config, lib, pkgs, ... }:

{
  home.packages = lib.mkIf config.lsp.docker.enable [
    pkgs.dockerfile-language-server-nodejs
  ];
}
