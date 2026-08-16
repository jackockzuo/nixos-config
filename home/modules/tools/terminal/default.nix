# ============================================================
# tools/terminal/default.nix —— 终端体验领域聚合
# 原则：工具链由 nix 管理（与发行版解耦）；个体应用不在此列
# 每个工具独立文件（有配置的工具每工具一文件），可按需增删
# 新增 → 新建 <工具>.nix 并在此加一行；预留 → 取消注释
# 纯安装包（无配置）由 tools/default.nix 的 home.packages 统一管理
# ============================================================
{ pkgs, ... }:

{
  imports = [
    ./fish.nix # fish shell（别名/缩写/函数 + Catppuccin 配色）
    ./starship.nix # starship 提示符（Powerline 布局）
    ./zoxide.nix # zoxide 智能 cd
    ./fzf.nix # fzf 模糊查找（Catppuccin Mocha 配色）
    ./bat.nix # bat 增强 cat（Catppuccin Mocha 主题）
    ./atuin.nix # 终端历史搜索（SQLite + TUI，接管 Ctrl-R）
    ./yazi.nix # yazi 终端文件管理器（Catppuccin Mocha 主题）
    ./zellij.nix # zellij 终端复用器（Catppuccin Mocha 主题）
    ./onefetch.nix # git 仓库信息面板（Catppuccin Mocha 配色）
  ];
}
