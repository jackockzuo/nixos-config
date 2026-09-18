# ============================================================
# nixvim.nix —— 编辑器（Nixvim，Home Manager 模块）
# 职责：Neovim 声明式配置（选项/插件/LSP/键位/fcitx5 状态联动）
# 引入：flake.nix 的 home-manager.users.<user>.imports 引入 inputs.nixvim.homeModules.nixvim
# ============================================================
{ my, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;

    # 全局 Leader 键
    globals.mapleader = " ";

    # 1. 基础选项 (vim.opt)
    opts = {
      number = true;
      relativenumber = true;
      termguicolors = true;
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      cursorline = true;
      mouse = "a";
      clipboard = "unnamedplus"; # y/p 走系统剪贴板
    };

    # 2. 主题 Catppuccin（flavor 与全局单一来源 my.catppuccin 同步）
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = my.catppuccin.flavor;
        transparent_background = true;
      };
    };

    # 3. 核心与手感插件
    plugins = {
      # 状态栏
      lualine = {
        enable = true;
        settings.options = {
          theme = "catppuccin";
          component_separators = "|";
          section_separators = "";
        };
      };

      # Git 增强
      gitsigns.enable = true;
      gitblame.enable = true;
      diffview.enable = true;

      # 文本对象增强（mini.ai：a/i + an/in/al/il 下一/上一，无 treesitter 依赖）
      mini-ai.enable = true;

      # 包裹操作（mini.surround：sa 添加 / sd 删除 / sr 替换 / sf 查找）
      mini-surround.enable = true;

      # 语法高亮 (Treesitter)
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };

      # 模糊搜索 (Telescope)
      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
        settings.defaults = {
          sorting_strategy = "ascending";
          layout_config = {
            prompt_position = "top";
          };
          prompt_prefix = "  ";
          selection_caret = " ";
        };
        keymaps = {
          "<leader>ff" = {
            action = "find_files";
            options.desc = "查找文件";
          };
          "<leader>fg" = {
            action = "live_grep";
            options.desc = "全文搜索";
          };
          "<leader>fb" = {
            action = "buffers";
            options.desc = "切换缓冲区";
          };
          "<leader>fh" = {
            action = "help_tags";
            options.desc = "帮助标签";
          };
          # Telescope LSP 导航
          "<leader>gd" = {
            action = "lsp_definitions";
            options.desc = "LSP 定义跳转 (telescope)";
          };
          "<leader>gr" = {
            action = "lsp_references";
            options.desc = "LSP 引用查找 (telescope)";
          };
          "<leader>gi" = {
            action = "lsp_implementations";
            options.desc = "LSP 实现查找 (telescope)";
          };
          "<leader>gt" = {
            action = "lsp_type_definitions";
            options.desc = "LSP 类型定义 (telescope)";
          };
          "<leader>ds" = {
            action = "lsp_document_symbols";
            options.desc = "LSP 文档符号 (telescope)";
          };
          "<leader>ws" = {
            action = "lsp_workspace_symbols";
            options.desc = "LSP 工作区符号 (telescope)";
          };
        };
      };

      # 代码补全 (nvim-cmp + LuaSnip)
      luasnip.enable = true;
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          mapping = {
            "<C-n>" = "cmp.mapping.select_next_item()";
            "<C-p>" = "cmp.mapping.select_prev_item()";
            "<C-y>" = "cmp.mapping.confirm({ select = true })";
            "<C-Space>" = "cmp.mapping.complete()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
          };
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "buffer"; }
            { name = "path"; }
          ];
          window = {
            completion.__raw = "cmp.config.window.bordered()";
            documentation.__raw = "cmp.config.window.bordered()";
          };
        };
        cmdline = {
          ":" = {
            mapping.__raw = "cmp.mapping.preset.cmdline()";
            sources = [
              { name = "path"; }
              { name = "cmdline"; }
            ];
          };
        };
      };

      # LSP 服务管理 (无需 Mason，由 Nix 自动管理二进制与依赖)
      lsp = {
        enable = true;
        servers = {
          # Nix 语言支持（已自动替你处理 nil 服务）
          nil_ls.enable = true;

          # 如有其他语言需求，直接开启对应选项（Nix 会自动安装对应 server 二进制）：
          # lua_ls.enable = true;
          # pyright.enable = true;
          # rust_analyzer = {
          #   enable = true;
          #   installCargo = false;
          #   installRustc = false;
          # };
        };
        keymaps.lspBuf = {
          "gd" = {
            action = "definition";
            desc = "跳转到定义";
          };
          "gr" = {
            action = "references";
            desc = "查找引用";
          };
          "K" = {
            action = "hover";
            desc = "悬停文档";
          };
          "<leader>rn" = {
            action = "rename";
            desc = "重命名";
          };
          "<leader>ca" = {
            action = "code_action";
            desc = "代码操作";
          };
        };
      };
    };

    # 4. 全局快捷键
    keymaps = [
      # Git blame
      {
        mode = "n";
        key = "gB";
        action = "<cmd>GitBlameToggle<CR>";
        options.desc = "切换 blame 显示";
      }
    ];

    # 5. 自动命令 (fcitx5 中英自动切换)
    # 说明：nixvim 无对应插件模块，只能用 autoCmd + fcitx5-remote（无更优声明式方案）
    autoCmd = [
      {
        event = [ "VimEnter" ];
        pattern = [ "*" ];
        callback.__raw = ''
          function()
            vim.fn.jobstart('fcitx5-remote -c')
          end
        '';
      }
      {
        event = [ "InsertLeave" ];
        pattern = [ "*" ];
        callback.__raw = ''
          function()
            vim.g.fcitx_state = vim.fn.system('fcitx5-remote')[0]
            vim.fn.jobstart('fcitx5-remote -c')
          end
        '';
      }
      {
        event = [ "InsertEnter" ];
        pattern = [ "*" ];
        callback.__raw = ''
          function()
            if vim.g.fcitx_state == '2' then
              vim.fn.jobstart('fcitx5-remote -o')
            end
          end
        '';
      }
    ];
  };
}
