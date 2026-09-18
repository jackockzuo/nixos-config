# shell-utils.nix —— 终端通用工具（atuin/bat/fzf/zoxide/eza）+ 通用 CLI
# 职责：shell 集成与「无专属领域」的通用终端 CLI 的唯一落点
# 归属原则（STANDARDS §3.1）：通用工具放这里；程序专属依赖随程序文件（如 yazi.nix）
# 注释约定：fish 集成统一用 type -q 守卫（容器兼容）
# ============================================================
{ lib, pkgs, ... }:

let
  # onefetch 无 HM 模块，用 pkgs.formats.yaml 生成器
  yamlFormat = pkgs.formats.yaml { };
in
{
  programs = {
    # atuin：终端历史搜索（SQLite + TUI，接管 Ctrl-R / ↑）
    # fish 集成用 type -q 守卫（容器兼容）(REF:2026-08-18-distrobox-container-fish-unknown-command)
    atuin = {
      enable = true;
      enableFishIntegration = false; # 集成交给下方守卫块
      settings = {
        enter_accept = true; # 回车直接执行选中历史
        search.filters = [
          "global"
          "host"
          "session"
          "directory"
        ];
        workspaces = true;
        show_preview = true;
        search_mode = "fuzzy";
        keymap_mode = "auto";
        style = "compact";
        inline_height = 24;
        exit_mode = "return-original";
        history_filter = [ ];
      };
    };

    # bat：cat 增强（语法高亮）
    # 主题由 catppuccin.bat 注入（themes + config.theme）
    bat = {
      enable = true;
      config = {
        paging = "never"; # 不分页直接输出
      };
    };

    # fzf：模糊查找（Ctrl-T 文件 / Alt-C 目录，Ctrl-R 让给 atuin）
    # 配色由 catppuccin.fzf 注入（FZF_DEFAULT_OPTS_FILE）
    fzf = {
      enable = true;
      enableFishIntegration = false; # 集成交给下方守卫块
      historyWidget.command = "";
    };

    # zoxide：智能 cd（模块自动装包，程序专属依赖不再各处重复声明）
    zoxide = {
      enable = true;
      enableFishIntegration = false; # 集成交给下方守卫块
    };

    # eza：ls 增强（模块只负责安装；fish 别名/缩写仍在 fish.nix 手写，避免双重 alias）
    eza = {
      enable = true;
      enableFishIntegration = false;
    };

    # 统一 fish 集成守卫块（atuin/fzf/zoxide）
    # 容器内工具不在 PATH → type -q 守卫静默跳过
    # ⚠️ 容器内 fish 3.3.1：必须用 type -q（command -q 需 fish 3.4+）
    fish.interactiveShellInit = lib.mkAfter ''
      if type -q atuin
          atuin init fish | source
      end
      if type -q fzf
          fzf --fish | source
      end
      if type -q zoxide
          zoxide init fish | source
      end
    '';
  };

  # 通用 CLI（纯安装，无 HM 模块；有官方模块的见上方 programs.*）
  home.packages = with pkgs; [
    # ---- 终端信息 / 图片 / 录屏 ----
    onefetch # git 仓库信息面板（配置见下方 xdg.configFile）
    timg # 终端图片
    ueberzugpp # 终端图片后端（yazi 等）
    vhs # 终端录屏（把操作录成 GIF/视频）

    # ---- 通用小工具 ----
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

    # ---- 媒体信息 ----
    mediainfo

    # ---- 容器 CLI（podman 系统服务在 modules/packages.nix）----
    distrobox
  ];

  # onefetch：git 仓库信息面板（Catppuccin Mocha）
  # 无 HM 模块，用 pkgs.formats.yaml 生成器
  xdg.configFile."onefetch/config.yml" = {
    source = yamlFormat.generate "onefetch-config.yml" {
      color = {
        title = "#cba6f7";
        diagonal = "#313244";
        underscores = "#313244";
        punctuation = "#a6adc8";
        description = "#cdd6f4";
        info = "#89b4fa";
        hash = "#f5c2e7";
        author = "#a6e3a1";
        email = "#94e2d5";
        branch = "#fab387";
        language = "#cdd6f4";
        languages = "#cdd6f4";
        license = "#cdd6f4";
        commits = "#f9e2af";
        performers = "#cdd6f4";
        statistics = "#cdd6f4";
        style = "#cdd6f4";
        all_commits = "#cdd6f4";
        block = "#cdd6f4";
      };
    };
  };
}
