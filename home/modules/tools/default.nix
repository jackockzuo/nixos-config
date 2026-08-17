# ============================================================
# tools/default.nix —— 开发工具链聚合入口（nix 管理）
# 架构：按领域分文件夹（terminal/monitoring/dev/theming），
#       文件夹内按工具分文件（有配置的工具每工具一文件）
# 原则：
#   - 工具链由 nix 管理（与发行版解耦）；个体应用不在此列
#   - 有配置的工具 → 新建 <领域>/<工具>.nix（用 programs.* 现代模块）
#   - 纯安装包（无配置）→ 在本文件 home.packages 按领域分组
# 新增 → 建领域文件并在下方 imports 加一行
# ============================================================
{ pkgs, ... }:

{
  imports = [
    ./terminal # 终端体验（fish/starship/fzf/atuin/yazi/...）
    ./monitoring # 系统监控（btop/cava）
    ./dev # 开发工具（git/neovim/lazygit/...）
    ./theming # 主题联动（matugen 壁纸→配色）
    ./social.nix # 社交（QQ 原生 Wayland 等）
    # ./wine.nix     # Wine 程序管理（需要时取消注释）
    ./ai.nix # 本地 AI（Ollama/LM Studio）
    ./office.nix # 办公效率（Obsidian/PDF 工具）
  ];

  # 纯安装包（无配置，按领域分组管理）
  home.packages = with pkgs; [
    # ── terminal 领域：终端图片工具 + git 信息面板 + 录屏 ──
    timg # 终端图片
    ueberzugpp # 终端图片后端
    onefetch # git 仓库信息面板
    vhs # 终端录屏（把操作录成 GIF/视频）

    # ── monitoring 领域：磁盘分析 + 日志/网络排障 ──
    duf # 磁盘空间
    dust # 空间树状图
    lnav # 日志文件/日志的 TUI 查看器（时间线+高亮+SQL 过滤）
    bandwhich # 实时网络带宽按进程归因

    # ── theming 领域：主题生成 ──
    matugen # 主题生成（壁纸→配色，配置见 theming/matugen.nix）

    # ── dev 领域：通用开发小工具 ──
    ripgrep # 搜索
    fd # 查找
    jq # JSON 处理
    tree # 目录树
    moreutils # 额外工具
    pandoc # 文档转换
    p7zip # 压缩（提供 7z 命令）
    unrar # 解压
    imagemagick # 图片处理
    tree-sitter # 语法树
    mcat
    dgop

    # ── dev 领域：密码管理 ──
    pass # 密码管理（gpg 加密，配置见 dev/pass.nix）
    pinentry-curses # gpg 主密码输入（终端版 pinentry）
  ];
}
