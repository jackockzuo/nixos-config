{ pkgs, my, ... }:

{
  programs.fish = {
    enable = true;
    # oh-my-fish 生态插件：声明式 fishPlugins 替代运行时 OMF（OMF 已停止维护）
    plugins = [
      {
        name = "transient-fish";
        src = pkgs.fishPlugins.transient-fish;
      } # 命令执行后提示符自动变短
      {
        name = "done";
        src = pkgs.fishPlugins.done;
      } # 长命令完成提醒（替代原 notify-long-command 函数）
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair;
      } # 括号/引号自动配对
      {
        name = "sponge";
        src = pkgs.fishPlugins.sponge;
      } # 常用命令彩色输出
      {
        name = "bang-bang";
        src = pkgs.fishPlugins.bang-bang;
      } # !! 展开上条命令
      {
        name = "fish-you-should-use";
        src = pkgs.fishPlugins.fish-you-should-use;
      } # 存在别名时提示（学习型）
      {
        name = "bass";
        src = pkgs.fishPlugins.bass;
      } # fish 里执行 bash 命令/脚本
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit;
      } # fzf 加持的 git 操作
      {
        name = "git-abbr";
        src = pkgs.fishPlugins.git-abbr;
      } # git 命令缩写（60+ 个，带补全）
    ];
    # 将静态别名置空，改到 interactiveShellInit 中动态定义
    shellAliases = { };

    interactiveShellInit = ''
      # 容器侦测
      set -l is_container (test -e /run/.containerenv; or test -n "$CONTAINER_ID")

      set fish_greeting ""

      # 配色由 catppuccin.fish 注入（shellInit theme choose；已下线 matugen 动态覆盖）

      # 宿主机专用（容器内跳过）
      if not set -q is_container[1]

          # Fastfetch
          if type -q fastfetch
              if not set -q FASTFETCH_RUN_ONCE
                  set -gx FASTFETCH_RUN_ONCE 1
                  fastfetch
              end
          end

          # Done 插件
          set -g __done_min_cmd_duration 10000
          set -g __done_notify_sound 0

          # 宿主机别名
          if type -q eza;      alias ls="eza --icons --git"; end
          if type -q bat;      alias cat="bat"; end
          if type -q lazygit;  alias lg="lazygit"; end
          if type -q nvim;     alias v="nvim"; end
          if type -q kitty;    alias ks="kitty --session work"; end

      else
          # 容器内：保持原生命令（跳过 alias 定义）
      end
    '';

    # fish 缩写（输入短词后按空格/回车自动展开）
    shellAbbrs = {
      # ── NixOS 高频 ──

      tg = "topgrade"; # 一键更新链（flake update + 检查 + 预构建切换）

      # ── git 高频 ──
      gst = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gpl = "git pull";
      gl = "git log --oneline --graph";
      gd = "git diff";

      # ── 目录导航（极高频）──
      ".." = "cd ..";
      "..." = "cd ../..";

      # ── 终端高频 ──
      ll = "eza -l --icons=auto --git"; # 长格式列表（替代原 la 函数）
      clip = "wl-copy"; # 剪贴板（配合 cliphist）
    };

    # fish 自动加载函数（值 = 函数体，HM 自动包裹 function ... end）
    functions = {

      # nr：唯一重建入口（快照 / + /home → nh 构建/diff/切换）
      #   nr               日常重建（不更新 inputs）
      #   nr -u            更新全部 flake inputs 再重建（topgrade 走这条）
      #   nr -U nixpkgs    只更新指定 input
      nr = ''
        set -l flake ${my.homeDirectory}/nixos-config
        echo "📸 snapper 快照 / + /home ..."
        sudo snapper -c root create -t single -d "nr before $(date +%Y%m%d-%H%M)"; or return 1
        sudo snapper -c home create -t single -d "nr before $(date +%Y%m%d-%H%M)"; or return 1
        nh os switch $argv $flake#${my.hostname}
      '';

      # 保留回滚位（STANDARDS §8）：nh clean 至少留 15 代 / 14 天内不删，执行前确认。
      # 禁用 nix-collect-garbage -d（会删光所有代际，丧失回滚能力）。
      clean-system = ''
        echo "🧹 清理 Nix（保留最近 15 代 / 14 天，维持回滚位）..."
        nh clean all --keep 15 --keep-since 14d --ask
        echo "✨ 完成"
      '';

      # yazi 退出后 cd 回目录（由 yazi.nix 模块 fish 集成生成，不重复定义）

    };
  };
}
