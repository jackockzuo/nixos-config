{ lib, ... }:

{
  # 极简双行布局 Starship 配置
  programs.starship = {
    enable = true;
    # type -q 守卫：容器内 starship 不存在时静默跳过 (REF:2026-08-18-distrobox-nc)
    enableFishIntegration = false;
    enableBashIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      # 左右分栏布局：第一行 = 导航 + 环境，第二行 = 输入提示符
      format = "$os$username$directory$git_branch$git_status\${custom.nix}$nix_shell$line_break$character";
      right_format = "$package$c$cpp$fortran$rust$java$haskell$python$go$nodejs$ruby$lua$perl$php$cmake$pixi$cmd_duration$jobs$status";

      add_newline = false;
      command_timeout = 500;

      palette = "catppuccin_mocha";

      # ── OS 图标 ──
      os = {
        disabled = false;
        style = "fg:red";
        format = "[$symbol]($style) ";
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

      # ── 用户名 ──
      username = {
        show_always = true;
        style_user = "fg:peach";
        style_root = "fg:red";
        format = "[$user]($style) ";
      };

      # ── 目录 ──
      directory = {
        style = "fg:teal";
        format = "in· [$path]($style)$read_only ";
        truncation_length = 3;
        truncation_symbol = "…/";
        # 🔒 目录只读时显示锁图标
        read_only = "🔒 ";
        # ⚠️ 2026-08-17：scan_for_workdir_files / scan_timeout 已在 starship 1.26 移除
        #   （schema 无此键，配置会触发 "Unknown key" 警告）→ 已删除，性能由 command_timeout 兜底
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = "󰝚 ";
          "Pictures" = " ";
          "Developer" = "󰲋 ";
        };
      };

      git_branch = {
        symbol = " ";
        style = "fg:yellow";
        format = "on· [$symbol$branch]($style) ";
      };
      git_status = {
        style = "fg:yellow";
        format = "[$all_status$ahead_behind]($style) ";
      };

      # ── 后台任务数 ──
      jobs = {
        symbol = "⚙ ";
        format = "[$symbol$number]($style) ";
        style = "fg:blue";
      };

      # ── 退出码 ──
      status = {
        format = "[$symbol$status]($style) ";
        style = "fg:red";
      };

      # ── 语言版本链：仅当项目含对应文件时显示 ──
      c = {
        symbol = " ";
        style = "fg:green";
        format = "[$symbol$name$version]($style) ";
      };
      cpp = {
        symbol = " ";
        style = "fg:green";
        format = "[$symbol$name$version]($style) ";
        disabled = false;
      };
      fortran = {
        symbol = "󱈚 ";
        style = "fg:green";
        format = "[$symbol$name$version]($style) ";
      };
      rust = {
        symbol = "";
        style = "fg:peach";
        format = "[$symbol$version]($style) ";
      };
      java = {
        symbol = " ";
        style = "fg:red";
        format = "[$symbol$version]($style) ";
      };
      haskell = {
        symbol = "";
        style = "fg:mauve";
        format = "[$symbol$version]($style) ";
      };
      python = {
        symbol = "";
        style = "fg:yellow";
        format = "[$symbol$version]($style) ";
      };

      # 以下模块用 detect_files / detect_extensions 指定触发文件（性能优化）
      # starship 1.26 起模块名 `go` 改名为 `golang` (REF:2026-08-17-starship-golang)
      golang = {
        symbol = " ";
        style = "fg:sky";
        format = "[$symbol$version]($style) ";
        detect_files = [ "go.mod" ];
      };
      nodejs = {
        symbol = " ";
        style = "fg:green";
        format = "[$symbol$version]($style) ";
        detect_files = [ "package.json" ];
      };
      ruby = {
        symbol = " ";
        style = "fg:red";
        format = "[$symbol$version]($style) ";
        detect_files = [
          ".ruby-version"
          "Gemfile"
        ];
      };
      lua = {
        symbol = " ";
        style = "fg:blue";
        format = "[$symbol$version]($style) ";
        # .lua-version 不通用，补充 *.lua 扩展名识别
        detect_files = [ ".lua-version" ];
        detect_extensions = [ "lua" ];
      };
      perl = {
        symbol = " ";
        style = "fg:teal";
        format = "[$symbol$version]($style) ";
        # cpanfile 不通用，补充 *.pl 扩展名识别
        detect_files = [ "cpanfile" ];
        detect_extensions = [ "pl" ];
      };
      php = {
        symbol = " ";
        style = "fg:mauve";
        format = "[$symbol$version]($style) ";
        detect_files = [ "composer.json" ];
      };
      cmake = {
        symbol = " ";
        style = "fg:blue";
        format = "[$symbol$version]($style) ";
      };
      pixi = {
        symbol = "󱄵 ";
        style = "fg:blue";
        format = "[$symbol$environment]($style) ";
      };

      # ── 项目版本识别：进入含 package.json/Cargo.toml 等项目自动显示版本 ──
      package = {
        symbol = "📦 ";
        style = "fg:green";
        format = "via· [$symbol$version]($style) ";
      };

      # ── Nix 项目目录标识（flake.nix/default.nix/shell.nix）──
      custom.nix = {
        command = "test -f flake.nix -o -f default.nix -o -f shell.nix && echo nix";
        when = true;
        symbol = "❄ ";
        style = "fg:green";
        format = "[$symbol$output]($style) ";
      };

      # ── nix shell：雪花符号 + 环境状态 ──
      nix_shell = {
        symbol = "❄ ";
        style = "fg:green";
        format = "via· [$symbol$state]($style) ";
      };

      # ── 命令耗时 ──
      cmd_duration = {
        min_time = 200;
        show_milliseconds = true;
        format = "⏱ [$duration]($style) ";
        style = "fg:overlay0";
        disabled = false;
      };

      # ── 换行 ──
      line_break = {
        disabled = false;
      };

      # ── 输入提示符 ──
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

  # fish 集成（type -q 守卫，容器兼容）(REF:2026-08-18-distrobox-nc)
  programs.fish.interactiveShellInit = lib.mkAfter ''
    if type -q starship
        if test "$TERM" != dumb
            starship init fish | source
        end
    end
  '';
}
