# ============================================================
# lsp.nix —— 语言服务器领域：汇总启停
#   设计：领域分文件夹，每个语言一个文件（每语言一文件），
#         本文件只做两件事：定义选项 + 统一启停开关，不装任何包
#   拒绝耦合：各语言文件互不引用，全部通过 config.lsp.<lang>.enable 控制
#   📋 共 13 种语言：
#     - 4 种默认启用（ENABLED）：cpp / rust / nix / typst
#     - 9 种默认禁用（DISABLED，按需开启）：python / lua / typescript /
#       go / bash / web / markdown / docker / toml
#     需要时把对应 config.lsp.<lang>.enable 改为 true（或 mkDefault true）
#   🔴 后续可扩展：java（jdt-language-server，jdtls 较重、需额外 JVM 配置）、
#     cmake（cmake-language-server，极少单独使用）—— 需要时再加文件即可
# ============================================================
{ lib, ... }:

{
  options.lsp = {
    # —— 默认启用（4）——
    cpp.enable = lib.mkEnableOption "C/C++ LSP（clangd）";
    rust.enable = lib.mkEnableOption "Rust LSP（rust-analyzer）";
    nix.enable = lib.mkEnableOption "Nix LSP（nil）";
    typst.enable = lib.mkEnableOption "Typst LSP（tinymist）";
    # —— 默认禁用（9），按需开启 ——
    python.enable = lib.mkEnableOption "Python LSP（pyright）";
    lua.enable = lib.mkEnableOption "Lua LSP（lua-language-server）";
    typescript.enable = lib.mkEnableOption "TypeScript/JavaScript LSP（typescript-language-server）";
    go.enable = lib.mkEnableOption "Go LSP（gopls）";
    bash.enable = lib.mkEnableOption "Bash LSP（bash-language-server）";
    web.enable = lib.mkEnableOption "Web 格式 LSP（vscode-langservers-extracted：JSON/YAML/HTML/CSS）";
    markdown.enable = lib.mkEnableOption "Markdown LSP（marksman）";
    docker.enable = lib.mkEnableOption "Dockerfile LSP（dockerfile-language-server-nodejs）";
    toml.enable = lib.mkEnableOption "TOML LSP（taplo）";
  };

  # 启用开关：4 种默认 true，9 种默认 false
  # 🔴 mkEnableOption 默认 false，这里仍显式写 mkDefault false，
  #    语义更清晰（默认禁用，按需启用），且保留被其他模块覆盖的能力
  config.lsp = {
    # —— 默认启用（4）——
    cpp.enable = lib.mkDefault true;
    rust.enable = lib.mkDefault true;
    nix.enable = lib.mkDefault true;
    typst.enable = lib.mkDefault true;
    # —— 默认禁用（9）：🔴 默认禁用，按需启用，改这里为 true 即可 ——
    python.enable = lib.mkDefault false;
    lua.enable = lib.mkDefault false;
    typescript.enable = lib.mkDefault false;
    go.enable = lib.mkDefault false;
    bash.enable = lib.mkDefault false;
    web.enable = lib.mkDefault false;
    markdown.enable = lib.mkDefault false;
    docker.enable = lib.mkDefault false;
    toml.enable = lib.mkDefault false;
  };

  imports = [
    ./cpp.nix
    ./rust.nix
    ./nix.nix
    ./typst.nix
    # —— 默认禁用（9）——
    ./python.nix
    ./lua.nix
    ./typescript.nix
    ./go.nix
    ./bash.nix
    ./web.nix
    ./markdown.nix
    ./docker.nix
    ./toml.nix
  ];
}
