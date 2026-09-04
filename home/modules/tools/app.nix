# ============================================================
# app.nix —— 本地应用
# ============================================================

{ pkgs, ... }:

{
  # QQ 原生 Wayland（ozone-platform=wayland）
  xdg.configFile."qq-flags.conf" = {
    force = true; # 覆盖原作者旧配置
    text = ''
      --ozone-platform=wayland
    '';
  };
  # 终端内的 AI 编码代理
  home.packages = with pkgs; [
    vscode
    zed

    opencode
    pi-coding-agent
    wpsoffice-cn
    zotero
    obsidian
    qq
    wechat

    # 纯安装包（无配置，按领域分组管理）
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
