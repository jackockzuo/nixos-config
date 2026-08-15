{ ... }:

{
  # 1. Fish Shell 基础配置
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting ""
      fastfetch
    '';
    shellAliases = {
      ls = "eza --icons";
      cat = "bat";
      lg = "lazygit";
      v = "nvim";
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
    	command eza --icons=auto --tree -- $argv
    end
  '';
  xdg.configFile."fish/functions/la.fish".text = ''
    function la
    	command eza -l --icons=auto -- $argv
    end
  '';
  # 2. 🔴 由 Nix 声明式构建你的专属 Powerline Starship 主题
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = "[](red)$os$username[](bg:peach fg:red)$directory[](bg:yellow fg:peach)$git_branch$git_status[](fg:yellow bg:green)$c$cpp$fortran$rust$java$haskell$python[](fg:green bg:sapphire)$cmake$pixi[](fg:sapphire bg:lavender)$time[ ](fg:lavender)$cmd_duration$line_break$character";

      palette = "catppuccin_mocha";

      os = {
        disabled = false;
        style = "bg:red fg:crust";
        symbols = {
          Windows = "";
          Ubuntu = "󰕈";
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "󰀵";
          Manjaro = "";
          Linux = "󰌽";
          Gentoo = "󰣨";
          Fedora = "󰣛";
          Alpine = "";
          Amazon = "";
          Android = "";
          AOSC = "";
          Arch = "󰣇";
          Artix = "󰣇";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
        };
      };

      username = {
        show_always = true;
        style_user = "bg:red fg:crust";
        style_root = "bg:red fg:crust";
        format = "[ $user]($style)";
      };

      directory = {
        style = "bg:peach fg:crust";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = "󰝚 ";
          "Pictures" = " ";
          "Developer" = "󰲋 ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:yellow";
        format = "[[ $symbol $branch ](fg:crust bg:yellow)]($style)";
      };
      git_status = {
        style = "bg:yellow";
        format = "[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)";
      };
      cmake = {
        symbol = " ";
        style = "bg:blue";
        format = "[[ $symbol$version ](fg:crust bg:sapphire)]($style)";
      };
      c = {
        symbol = " ";
        style = "bg:green";
        format = "[[ $symbol $name $version ](fg:crust bg:green)]($style)";
      };
      cpp = {
        symbol = " ";
        style = "bg:green fg:crust";
        format = "[ $symbol($name $version) ]($style)";
        disabled = false;
      };
      fortran = {
        symbol = "󱈚 ";
        style = "bg:green";
        format = "[[ $symbol $name $version ](fg:crust bg:green)]($style)";
      };
      rust = {
        symbol = "";
        style = "bg:green";
        format = "[[ $symbol$version ](fg:crust bg:green)]($style)";
      };
      pixi = {
        symbol = "󱄵 ";
        style = "bg:blue";
        format = "[[ $symbol $environment ](fg:crust bg:sapphire)]($style)";
      };
      java = {
        symbol = " ";
        style = "bg:green";
        format = "[[ $symbol $version ](fg:crust bg:green)]($style)";
      };
      haskell = {
        symbol = "";
        style = "bg:green";
        format = "[[ $symbol$version ](fg:crust bg:green)]($style)";
      };
      python = {
        symbol = "";
        style = "bg:green";
        format = "[[ $symbol $version ](fg:crust bg:green)]($style)";
      };
      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:lavender";
        format = "[[  $time ](fg:crust bg:lavender)]($style)";
      };
      cmd_duration = {
        show_milliseconds = true;
        format = " in $duration ";
        style = "fg:text";
        disabled = false;
      };
      line_break = {
        disabled = false;
      };
      character = {
        disabled = false;
        success_symbol = "[❯](bold fg:green)";
        error_symbol = "[❯](bold fg:red)";
        vimcmd_symbol = "[❮](bold fg:green)";
      };

      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        mauve = "#cba6f7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
        text = "#cdd6f4";
        subtext1 = "#bac2de";
        subtext0 = "#a6adc8";
        overlay2 = "#9399b2";
        overlay1 = "#7f849c";
        overlay0 = "#6c7086";
        surface2 = "#585b70";
        surface1 = "#45475a";
        surface0 = "#313244";
        base = "#1e1e2e";
        mantle = "#181825";
        crust = "#11111b";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.bat = {
    enable = true;
  };
}
