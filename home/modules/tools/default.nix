# tools/default.nix —— 开发工具链聚合（定位地图，扁平一层）
# 每行 import 带职责注释
{ ... }:

{
  imports = [
    ./fish.nix # fish shell（别名/插件/交互初始化）
    ./starship.nix # 提示符（Powerline 布局）
    ./yazi.nix # 终端文件管理器（Catppuccin Mocha）
    ./shell-utils.nix # 终端通用工具 + shell 集成（atuin/bat/fzf/zoxide/eza + 通用 CLI）
    ./dev.nix # 开发工具合并（git/gh/lazygit/direnv/tealdeer/topgrade/pass + 编辑器 + LSP）
    ./nixvim.nix # 编辑器（含 fcitx5 状态联动）
    ./monitoring.nix # 监控合并（btop/cava + duf/dust/lnav/bandwhich）
  ];
}
