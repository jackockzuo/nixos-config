_:

{
  # yazi：终端文件管理器（Catppuccin Mocha 主题）
  # 不启用 enableFishIntegration —— 其会生成 fish/functions/y.fish，
  # 与 fish.nix 中手写的 y.fish 冲突（同一目标文件）
  programs.yazi = {
    enable = true;
    # 显式采用新默认 "y"（stateVersion < 26.05 时 HM 默认是 legacy "yy"，会产生弃用警告）
    shellWrapperName = "y";

    # 主题：Catppuccin Mocha（yazi 0.3+ Rgba 风格配色）
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
    # 主配置：显示隐藏文件、自然排序、目录置顶
    # 🔴 必须有非空 settings 才会生成 yazi.toml
    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
      };
    };
  };
  # yazi 首次运行自动生成默认配置，force 避免 checkLinkTargets 冲突
  xdg.configFile."yazi/yazi.toml".force = true;
}
