# ============================================================
# tools/default.nix —— 开发工具链聚合（定位地图，扁平一层）
# 架构量化规则（STANDARDS §2）：一文件一领域、目录 ≤2 层、
# 无开关矩阵、无预留空壳；每行 import 带职责注释
# ============================================================
{ pkgs, ... }:

{
  imports = [
    ./fish.nix # fish shell（别名/插件/交互初始化）
    ./starship.nix # 提示符（Powerline 布局）
    ./yazi.nix # 终端文件管理器（Catppuccin Mocha）
    ./shell-utils.nix # 终端小工具合并（atuin/bat/fzf/onefetch/zoxide）
    ./dev.nix # 开发工具合并（git/gh/lazygit/direnv/tealdeer/topgrade/pass + 编辑器 + LSP）
    ./neovim.nix # 编辑器（含 fcitx5 状态联动）
    ./monitoring.nix # 监控合并（btop/cava）
    ./matugen.nix # 主题联动（壁纸→fish 配色）
    ./social.nix # 社交（QQ 原生 Wayland / 微信）
    ./ai.nix # 本地 AI（终端编码代理 opencode）
    ./office.nix # 办公（WPS/Zotero/Obsidian）
  ];

  # 纯安装包（无配置，按领域分组管理）
  home.packages = with pkgs; [
    # ── 终端领域：终端图片工具 + 信息面板 + 录屏 ──
    timg # 终端图片
    ueberzugpp # 终端图片后端
    onefetch # git 仓库信息面板
    vhs # 终端录屏（把操作录成 GIF/视频）

    # ── 监控领域：磁盘分析 + 日志/网络排障 ──
    duf # 磁盘空间
    dust # 空间树状图
    lnav # 日志文件/日志的 TUI 查看器（时间线+高亮+SQL 过滤）
    bandwhich # 实时网络带宽按进程归因

    # ── 开发领域：通用开发小工具 ──
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

    # ── 密码管理 ──
    pass # 密码管理（gpg 加密，配置见 dev.nix）
    pinentry-curses # gpg 主密码输入（终端版 pinentry）
  ];
}
