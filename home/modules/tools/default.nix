# ============================================================
# tools/default.nix —— 开发工具链聚合（nix 管理）
# 原则：工具链由 nix 管理（与发行版解耦）；个体应用不在此列
# 每个子模块独立关注点，可按需增删
# 新增 → 新建 <关注点>.nix 并在此加一行；预留 → 取消注释
# ============================================================
{ pkgs, ... }:

{
  imports = [
    ./shell.nix # fish + starship + zoxide/fzf/bat
    ./neovim.nix # 编辑器（含 fcitx5 状态联动）
    ./social.nix # 社交（QQ 原生 Wayland 等）
    ./opencode.nix # AI 编码助手（opencode CLI）
    # ./wine.nix     # Wine 程序管理（需要时取消注释）

    # ---- 🔮 预留模块（需要时取消注释）----
    # ./dev.nix # 开发语言/数据库客户端
    # ./ai.nix # 本地 AI（Ollama/LM Studio）
    # ./office.nix # 办公效率（Obsidian/PDF 工具）
  ];

  # 开发工具链（nix 管理）
  home.packages = with pkgs; [
    # CLI 增强
    btop # 系统监控
    yazi # 终端文件管理器
    lazygit # git TUI
    ripgrep # 搜索
    fd # 查找
    duf # 磁盘空间
    dust # 空间树状图
    # 终端增强
    jq # JSON 处理
    tree # 目录树
    moreutils # 额外工具
    # 终端美化
    timg # 终端图片
    ueberzugpp # 终端图片后端
    cava # 音频可视化
    matugen # 主题生成
    # 下载/转换 
    pandoc # 文档转换
    p7zip # 压缩
    unrar # 解压
    imagemagick # 图片处理
    tree-sitter # 语法树
    mcat
    dgop
    vscode
    zed
  ];

  # topgrade 一键升级（用 programs.topgrade 管理配置，见下）
  # 🔴 topgrade 对 NixOS 默认跑传统模式 `nixos-rebuild switch --upgrade`，
  #    会去 /etc/nixos/ 找 configuration.nix——但本仓库是 flake 架构（/etc/nixos 为空）→ 报错。
  #    解决方案：disable 内置 system 步骤 + 自定义命令跑 flake rebuild。
  programs.topgrade = {
    enable = true;
    settings = {
      misc = {
        # 禁用内置 NixOS 系统更新（传统模式，找不到 flake 配置）
        disable = [ "system" ];
        # 开头就缓存 sudo 凭证，避免中途卡密码
        pre_sudo = true;
        set_title = false;
      };
      commands = {
        "NixOS flake rebuild" = "sudo nixos-rebuild switch --flake /home/ran/nixos-config#omen";
      };
    };
  };
  # 🔴 force 覆盖已存在的 ~/.config/topgrade.toml：
  # topgrade 首次运行时自动生成的默认模板（全注释）与 HM 声明式配置冲突，
  # 不设 force 会导致 home-manager activation 整体失败（checkLinkTargets 报
  # "would be clobbered"），连带 fastfetch 等其他新配置全部无法部署。
  xdg.configFile."topgrade.toml".force = true;

  # 开发者工具配置
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "ran";
        email = "jackocksmic@outlook.com";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };
  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };
  programs.tealdeer = {
    enable = true;
    settings = {
      updates = {
        auto_update = true;
      };
    };
  };
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };
}
