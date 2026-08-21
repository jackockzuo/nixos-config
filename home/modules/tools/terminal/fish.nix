{ pkgs, ... }:

{
  # 1. Fish Shell 基础配置
  programs.fish = {
    enable = true;
    # 🌊 oh-my-fish 生态插件：声明式 fishPlugins 替代运行时 OMF
    # （OMF 已停止维护且与声明式配置冲突；nixpkgs 的 fishPlugins 由 Nix 构建、
    #   HM 生成 conf.d/plugin-*.fish 自动加载，插件随系统一起进入 store，完全声明式）
    # 插件名/源码均来自 pkgs.fishPlugins（nixpkgs 打包，已验证存在）
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
  shellAliases = {}; 

  interactiveShellInit = ''
    # 🔍 环境侦测：是否处于容器内部
    set -l is_container (test -e /run/.containerenv; or test -n "$CONTAINER_ID")

    set fish_greeting ""

    # --- 🎨 基础配色 (无需二进制文件，容器内外通用) ---
    set fish_color_normal #cdd6f4
    set fish_color_command #89b4fa
    set fish_color_param #cdd6f4
    set fish_color_error #f38ba8
    set fish_color_quote #a6e3a1
    set fish_color_operator #94e2d5
    set fish_color_redirection #f9e2af
    set fish_color_autosuggestion #585b70
    set fish_color_selection --background=#585b70
    set fish_color_search_match --background=#585b70
    set fish_color_cwd #a6e3a1
    set fish_color_valid_path --underline
    set fish_color_option #f5c2e7

    if test -f ~/.config/fish/colors.matugen.fish
        source ~/.config/fish/colors.matugen.fish
    end

    # --- 🛡️ 安全防御：仅在非容器环境（宿主机）加载的部分 ---
    if not set -q is_container[1]
        
        # ❄️ Fastfetch
        if type -q fastfetch
            if not set -q FASTFETCH_RUN_ONCE
                set -gx FASTFETCH_RUN_ONCE 1
                fastfetch
            end
        end

        # ⏱️ Done 插件
        set -g __done_min_cmd_duration 10000
        set -g __done_notify_sound 0

        # 🔗 宿主机专用别名 (通过 alias 命令动态定义)
        if type -q eza;      alias ls="eza --icons --git"; end
        if type -q bat;      alias cat="bat"; end
        if type -q lazygit;  alias lg="lazygit"; end
        if type -q nvim;     alias v="nvim"; end
        if type -q kitty;    alias ks="kitty --session work"; end

    else
        # --- 📦 容器内特殊配置 (可选) ---
        # 如果你想在容器里知道你在哪，可以改一下提示符颜色或添加提示
        # echo "📦 Inside Distrobox: (hostname)"
        
        # 在容器里，我们通常希望 ls 就是原生 ls，cat 就是原生 cat
        # 这里不需要写，因为我们跳过了上面的 alias 定义
    end
  '';

    # ⌨️ fish 缩写（输入短词后按空格/回车自动展开；已避开与别名/函数冲突的键）
    # 现代 HM 写法：shellAbbrs 类型为 attrsOf (either str abbrModule)，
    # 简单的 git 缩写直接用字符串值即可（即现代简化形式）；
    # 需要 position / setCursor 等高级特性时才写成 attrset
    shellAbbrs = {
      nr = "nixos-rebuild switch --flake ~/nixos-config#omen";
      gst = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gpl = "git pull";
      gl = "git log --oneline --graph";
      gd = "git diff";
      tl = "tldr";
    };
  };
  xdg.configFile = {
    # 🔴 100% 兼容的方式：直接生成 Fish 自动加载函数文件 ~/.config/fish/functions/clean-system.fish
    "fish/functions/clean-system.fish".text = ''
      function clean-system
          echo "🧹 正在清理 Nix 废弃历史版本..."
          sudo nix-collect-garbage -d

          echo "🧹 正在清理 NixOS 旧系统代（保留最近 5 代）..."
          sudo nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system

          echo "✨ 系统保洁完成，恢复极致清爽！"
      end
    '';

    # 迁移自 minimal-niri-dotfiles：y (yazi 退出后 cd 回目录) / lt (eza 树状) / la (eza 长格式)
    # 注：y.fish 手写在此处（与 yazi.nix 模块的 enableFishIntegration 互斥——
    # 两者都会生成同一 fish/functions/y.fish，故 yazi.nix 不启用 fish 集成）
    "fish/functions/y.fish".text = ''
      function y
      	set tmp (mktemp -t "yazi-cwd.XXXXXX")
      	yazi $argv --cwd-file="$tmp"
      	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
      		builtin cd -- "$cwd"
      	end
      	rm -f -- "$tmp"
      end
    '';
    "fish/functions/lt.fish".text = ''
      function lt
      	command eza --icons=auto --tree --git -- $argv
      end
    '';
    "fish/functions/la.fish".text = ''
      function la
      	command eza -l --icons=auto --git -- $argv
      end
    '';
  };
}
