# ============================================================
# tools/dev/default.nix —— 开发工具领域聚合
# 原则：工具链由 nix 管理（与发行版解耦）；个体应用不在此列
# 每个工具独立文件（有配置的工具每工具一文件），可按需增删
# 新增 → 新建 <工具>.nix 并在此加一行；预留 → 取消注释
# 纯安装包（无配置）由 tools/default.nix 的 home.packages 统一管理
# ============================================================
_:

{
  imports = [
    ./git.nix # git 版本控制
    ./direnv.nix # direnv 目录环境
    ./tealdeer.nix # tldr 手册（简洁命令示例）
    ./gh.nix # GitHub CLI
    ./topgrade.nix # 一键升级
    ./lazygit.nix # git TUI（Catppuccin Mocha 主题）
    ./neovim.nix # 编辑器（含 fcitx5 状态联动）
    ./lsp/lsp.nix # 语言服务器（LSP），每语言一文件，本文件统一启停    ./languages.nix # 开发语言/数据库客户端
    ./pass.nix # pass 密码管理（gpg 加密）
  ];
}
