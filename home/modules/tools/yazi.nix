_:

{
  # yazi：终端文件管理器（Catppuccin Mocha 主题）
  # 现代化改造：原 terminal-theme.nix 用 xdg.configFile 手写 theme.toml，
  # 现改用 HM 的 programs.yazi 模块（rev 83b7606d），theme 选项为 toml
  # 生成器 attrset（pkgs.formats.toml），自动序列化为 ~/.config/yazi/theme.toml
  # （模块源码：modules/programs/yazi.nix，theme 类型继承自 tomlFormat）
  #
  # 注：不启用 enableFishIntegration —— 其会通过 fish.functions 生成
  # fish/functions/y.fish，与 fish.nix 中手写的 y.fish 冲突（同一目标文件）
  programs.yazi = {
    enable = true;
    # 显式采用新默认 "y"（stateVersion < 26.05 时 HM 默认是 legacy "yy"，
    # 会产生弃用警告；此处未启用 fish integration，仅消除警告不产生冲突）
    shellWrapperName = "y";

    # 主题：原 theme.toml 内容按 [段] → attrset 键、行内表 → attrset 的
    # 一一对应关系转换（yazi 0.3+ Rgba 风格配色，值完全一致）
    theme = {
      manager = {
        cwd = {
          fg = "#89b4fa";
        };
        hovered = {
          fg = "#cdd6f4";
          bg = "#313244";
        };
        preview_hovered = {
          underline = true;
        };
        find_keyword = {
          fg = "#f9e2af";
          italic = true;
        };
        find_position = {
          fg = "#f9e2af";
          bg = "#585b70";
        };
        marker_selected = {
          fg = "#f38ba8";
        };
        marker_copied = {
          fg = "#a6e3a1";
        };
        marker_cut = {
          fg = "#f9e2af";
        };
        tab_active = {
          fg = "#11111b";
          bg = "#cba6f7";
        };
        tab_inactive = {
          fg = "#cdd6f4";
          bg = "#313244";
        };
      };
      status = {
        separator_open = "";
        separator_close = "";
        mode_normal = {
          fg = "#11111b";
          bg = "#cba6f7";
          bold = true;
        };
        mode_select = {
          fg = "#11111b";
          bg = "#a6e3a1";
          bold = true;
        };
        mode_unset = {
          fg = "#11111b";
          bg = "#f9e2af";
          bold = true;
        };
      };
      input = {
        border = {
          fg = "#89b4fa";
        };
        title = {
          fg = "#89b4fa";
        };
      };
      filetype.rules = [
        {
          mime = "image/*";
          fg = "#a6e3a1";
        }
        {
          mime = "video/*";
          fg = "#f38ba8";
        }
        {
          mime = "audio/*";
          fg = "#f9e2af";
        }
        {
          mime = "text/*";
          fg = "#94e2d5";
        }
        {
          name = "*/";
          fg = "#89b4fa";
        }
        {
          name = "*.rs";
          fg = "#fab387";
        }
        {
          name = "*.py";
          fg = "#f9e2af";
        }
        {
          name = "*.js";
          fg = "#f9e2af";
        }
        {
          name = "*.ts";
          fg = "#f5c2e7";
        }
        {
          name = "*.nix";
          fg = "#89b4fa";
        }
        {
          name = "*.md";
          fg = "#a6e3a1";
        }
        {
          name = "*.json";
          fg = "#f9e2af";
        }
      ];
    };
    # 主配置（yazi.toml）：常用设置——显示隐藏文件、自然排序、目录置顶
    # 🔴 必须有非空 settings 才会生成 yazi.toml（模块 mkIf cfg.settings != {}），
    #    只写 force 不写内容会导致 activation 报 "source 无值" 错误
    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
      };
    };
  };
  # yazi 首次运行会自动生成默认配置，force = true 避免与自动生成的默认
  # yazi.toml 冲突（theme.toml 由模块生成、当前部署无 force 且工作正常，
  # 与迁移前行为一致）
  xdg.configFile."yazi/yazi.toml".force = true;
  # kitty 终端支持 yazi 图片预览：kitty graphics protocol 内置于 yazi 0.4+，无需额外配置
}
