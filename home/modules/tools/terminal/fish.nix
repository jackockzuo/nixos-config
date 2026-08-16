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
      { name = "transient-fish"; src = pkgs.fishPlugins.transient-fish; }    # 命令执行后提示符自动变短
      { name = "done"; src = pkgs.fishPlugins.done; }                        # 长命令完成提醒（替代原 notify-long-command 函数）
      { name = "autopair"; src = pkgs.fishPlugins.autopair; }                # 括号/引号自动配对
      { name = "sponge"; src = pkgs.fishPlugins.sponge; }                    # 常用命令彩色输出
      { name = "bang-bang"; src = pkgs.fishPlugins.bang-bang; }              # !! 展开上条命令
      { name = "fish-you-should-use"; src = pkgs.fishPlugins.fish-you-should-use; } # 存在别名时提示（学习型）
      { name = "bass"; src = pkgs.fishPlugins.bass; }                        # fish 里执行 bash 命令/脚本
      { name = "forgit"; src = pkgs.fishPlugins.forgit; }                    # fzf 加持的 git 操作
      { name = "git-abbr"; src = pkgs.fishPlugins.git-abbr; }                # git 命令缩写（60+ 个，带补全）
    ];
    interactiveShellInit = ''
      set fish_greeting ""
      # 🎨 fish 语法高亮 + 自动补全配色（Catppuccin Mocha 主题）
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
      # ❄️ fastfetch 仅每次登录会话运行一次（嵌套 shell 不重复）
      if not set -q FASTFETCH_RUN_ONCE
          set -gx FASTFETCH_RUN_ONCE 1
          fastfetch
      end
      # 🎨 matugen 动态配色（换壁纸自动更新，文件不存在时跳过）
      # 在静态 Catppuccin 颜色之后 source，动态颜色优先覆盖
      if test -f ~/.config/fish/colors.matugen.fish
          source ~/.config/fish/colors.matugen.fish
      end
      # ⏱️ done 插件配置：长命令完成提醒（替代原 notify-long-command 函数，功能更强：
      # 超时 + 桌面通知 + 失败时 critical 级别；配置通过 __done_* 变量，见 https://github.com/franciscolourenco/done）
      set -g __done_min_cmd_duration 10000    # 10 秒阈值（同原 notify-long-command）
      set -g __done_notify_sound 0            # 关闭通知音（静默通知）
    '';
    shellAliases = {
      ls = "eza --icons --git";
      cat = "bat";
      lg = "lazygit";
      v = "nvim";
      # 🔤 kitty 工作会话（会话文件 ~/.config/kitty/work，--session 相对路径直接相对配置目录解析）
      ks = "kitty --session work";
    };
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
  # 🔴 100% 兼容的方式：直接生成 Fish 自动加载函数文件 ~/.config/fish/functions/clean-system.fish
  xdg.configFile."fish/functions/clean-system.fish".text = ''
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
  xdg.configFile."fish/functions/y.fish".text = ''
    function y
    	set tmp (mktemp -t "yazi-cwd.XXXXXX")
    	yazi $argv --cwd-file="$tmp"
    	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
    		builtin cd -- "$cwd"
    	end
    	rm -f -- "$tmp"
    end
  '';
  xdg.configFile."fish/functions/lt.fish".text = ''
    function lt
    	command eza --icons=auto --tree --git -- $argv
    end
  '';
  xdg.configFile."fish/functions/la.fish".text = ''
    function la
    	command eza -l --icons=auto --git -- $argv
    end
  '';
}
