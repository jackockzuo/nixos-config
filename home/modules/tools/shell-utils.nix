# shell-utils.nix —— 终端实用工具（atuin/bat/fzf/onefetch/zoxide）
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
    # fish 集成用 type -q 守卫（容器兼容）(REF:2026-08-18-distrobox-nc)
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

    # bat：cat 增强（语法高亮，Catppuccin Mocha）
    bat = {
      enable = true;
      config = {
        # 主题名必须带空格（bat 内置名大小写敏感）：Catppuccin Mocha (REF:2026-08-30-bat-theme)
        theme = "Catppuccin Mocha";
        paging = "never"; # 不分页直接输出
      };
    };

    # fzf：模糊查找（Ctrl-T 文件 / Alt-C 目录，Ctrl-R 让给 atuin）(REF:2026-08-18-fzf-atuin)
    fzf = {
      enable = true;
      enableFishIntegration = false; # 集成交给下方守卫块
      colors = {
        "fg" = "#cdd6f4";
        "bg" = "-1"; # 透明背景
        "hl" = "#f38ba8";
        "fg+" = "#cdd6f4";
        "bg+" = "#313244";
        "hl+" = "#f38ba8";
        "info" = "#cba6f7";
        "prompt" = "#cba6f7";
        "pointer" = "#f5c2e7";
        "marker" = "#f5c2e7";
        "spinner" = "#f5c2e7";
        "header" = "#f9e2af";
      };
      historyWidget.command = "";
    };

    # zoxide：智能 cd
    zoxide = {
      enable = true;
      enableFishIntegration = false; # 集成交给下方守卫块
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
