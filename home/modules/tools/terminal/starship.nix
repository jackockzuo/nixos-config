_:

{
  # 极简双行布局 Starship 配置
  # 设计原则：
  #   1. 极简主义：纯前景色文本 + 符号，无任何背景色块（移除全部 Powerline bg 样式）
  #   2. 高性能：只保留必要模块 + 目录扫描/外部命令双重超时
  #   3. 信息丰富：OS 图标 + 用户名 + 路径 + git 状态 + 多语言环境 + 命令耗时
  #   4. 双行布局：第一行 = 状态信息，第二行 = 输入提示符
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      # ── 左右分栏布局（spaceship 风格）──
      # 第一行：左侧导航（OS/用户/目录/git/nix）+ 右侧环境（语言链/耗时/任务/退出码）
      # 第二行：输入提示符。语言链右对齐不占左侧空间，多语言项目也不冗杂
      format = "$os$username$directory$git_branch$git_status\${custom.nix}$nix_shell$line_break$character";
      right_format = "$package$c$cpp$fortran$rust$java$haskell$python$go$nodejs$ruby$lua$perl$php$cmake$pixi$cmd_duration$jobs$exit_code";

      # ── 性能优化 ──
      # add_newline = false：紧凑布局，提示符之间不插入空行
      add_newline = false;
      # command_timeout = 500：等待外部命令（python --version / go version / node --version 等）返回版本的最大毫秒数，防止个别命令卡住
      command_timeout = 500;

      palette = "catppuccin_mocha";

      # ── OS 图标：红色符号，标志系统身份 ──
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

      # ── 用户名：常显（root 红色警示，普通用户桃色）──
      username = {
        show_always = true;
        style_user = "fg:peach";
        style_root = "fg:red";
        format = "[$user]($style) ";
      };

      # ── 目录：青色路径，截断至 3 级，常用目录替换为图标 ──
      directory = {
        style = "fg:teal";
        format = "in· [$path]($style)$read_only ";
        truncation_length = 3;
        truncation_symbol = "…/";
        # 🔒 目录只读（无写权限）时后缀显示锁图标（spaceship DIR_LOCK 同款）
        read_only = "🔒 ";
        # 性能优化：不递归扫描上级目录，只检查当前目录，识别更快
        scan_for_workdir_files = false;
        # 目录扫描超时（毫秒），深层/大目录立即放弃，不拖慢提示符
        scan_timeout = 30;
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = "󰝚 ";
          "Pictures" = " ";
          "Developer" = "󰲋 ";
        };
      };

      # ── git 状态：黄色分支 + 变更标记 ──
      git_branch = {
        symbol = " ";
        style = "fg:yellow";
        format = "on· [$symbol$branch]($style) ";
      };
      git_status = {
        style = "fg:yellow";
        format = "[$all_status$ahead_behind]($style) ";
      };

      # ── 后台任务数：有后台任务时显示 ⚙ N（spaceship jobs 同款）──
      jobs = {
        symbol = "⚙ ";
        format = "[$symbol$number]($style) ";
        style = "fg:blue";
      };

      # ── 退出码：上次命令非零时显示红色 ✘（spaceship exit_code 同款）──
      exit_code = {
        format = "[✘ $number]($style) ";
        style = "fg:red";
      };

      # ── 语言版本链：仅当项目含对应文件时显示 ──
      # 颜色使用各语言的经典色（无背景）；前 7 个模块走 starship 默认 detect 规则
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

      # 以下模块用 detect_files / detect_extensions 精确指定触发文件，避免扫描无关目录（性能优化）
      go = {
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

      # ── Nix 项目目录标识（flake.nix/default.nix/shell.nix 检测）──
      # 与 nix_shell（环境状态 pure/impure）区分：目录是 Nix 项目显示 ❄ nix，进入 nix develop 则右侧显示 ❄ pure
      # 性能：每次提示符渲染只跑一次 `test -f`（微秒级），command_timeout = 500 已兜底，无感知开销
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

      # ── 命令耗时：min_time = 200ms 几乎每条命令都记录；overlay0 灰色不抢注意力 ──
      cmd_duration = {
        min_time = 200;
        show_milliseconds = true;
        format = "⏱ [$duration]($style) ";
        style = "fg:overlay0";
        disabled = false;
      };

      # ── 换行：第一行状态 → 第二行输入提示符 ──
      line_break = {
        disabled = false;
      };

      # ── 输入提示符：成功绿色 ❯ / 失败红色 ❯ ──
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
}
