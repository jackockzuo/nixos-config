{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;

    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim
      lualine-nvim
      gitsigns-nvim
      nvim-treesitter.withAllGrammars
      # 文件搜索 (telescope)
      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      # 补全 (nvim-cmp + LuaSnip)
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      luasnip
      cmp_luasnip
      # LSP (mason + lspconfig)
      nvim-lspconfig
      mason-nvim
      mason-lspconfig-nvim
      # 手感插件: treesitter 文本对象 (af/if/ac/ic/ab/ib 选择, ]m/[m 跳转函数)
      nvim-treesitter-textobjects
      # 手感插件: surround 包裹 (ys/cs/ds, Lua 版替代 vim-surround)
      nvim-surround
      # 手感插件: git 增强 — blame 虚拟文本 + diffview 查看 diff/merge
      git-blame-nvim
      diffview-nvim
    ];

    initLua = ''
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.termguicolors = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true
      vim.opt.cursorline = true
      vim.opt.mouse = 'a'
      vim.opt.clipboard = 'unnamedplus'   -- 迁移自 minimal-niri-dotfiles: y/p 直接走系统剪贴板

      -- 迁移自 minimal-niri-dotfiles: fcitx5 输入法状态切换
      -- InsertLeave 时切回英文并记住状态，InsertEnter 时若是中文则恢复
      vim.g.fcitx_state = vim.fn.system('fcitx5-remote')[0]
      vim.api.nvim_create_autocmd('InsertLeave', {
        pattern = '*',
        callback = function()
          vim.g.fcitx_state = vim.fn.system('fcitx5-remote')[0]
          vim.fn.jobstart('fcitx5-remote -c')
        end,
      })
      vim.api.nvim_create_autocmd('InsertEnter', {
        pattern = '*',
        callback = function()
          if vim.g.fcitx_state == '2' then
            vim.fn.jobstart('fcitx5-remote -o')
          end
        end,
      })
      vim.api.nvim_create_autocmd('VimEnter', {
        pattern = '*',
        callback = function()
          vim.fn.jobstart('fcitx5-remote -c')
        end,
      })

      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
      })
      vim.cmd.colorscheme("catppuccin")

      require("lualine").setup({
        options = {
          theme = "catppuccin",
          component_separators = "|",
          section_separators = "",
        }
      })

      require("gitsigns").setup()

      -- 文件搜索: telescope 配置 + 快捷键 (leader 默认空格)
      vim.g.mapleader = " "
      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = { prompt_position = "top" },
          prompt_prefix = "  ",
          selection_caret = " ",
        },
      })
      local builtin = require("telescope.builtin")
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '查找文件' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '全文搜索' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = '切换缓冲区' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '帮助标签' })

      -- LSP 导航: telescope 浮动窗口（现代体验），原有 gd/gr/K 原生跳转保留（快速单跳）
      -- <leader>ca 已在 LSP on_attach 中定义（vim.lsp.buf.code_action），此处不重复
      vim.keymap.set('n', '<leader>gd', builtin.lsp_definitions, { desc = 'LSP 定义跳转 (telescope)' })
      vim.keymap.set('n', '<leader>gr', builtin.lsp_references, { desc = 'LSP 引用查找 (telescope)' })
      vim.keymap.set('n', '<leader>gi', builtin.lsp_implementations, { desc = 'LSP 实现查找 (telescope)' })
      vim.keymap.set('n', '<leader>gt', builtin.lsp_type_definitions, { desc = 'LSP 类型定义 (telescope)' })
      vim.keymap.set('n', '<leader>ds', builtin.lsp_document_symbols, { desc = 'LSP 文档符号 (telescope)' })
      vim.keymap.set('n', '<leader>ws', builtin.lsp_workspace_symbols, { desc = 'LSP 工作区符号 (telescope)' })

      -- 补全: nvim-cmp + LuaSnip (风格与 catppuccin 匹配, 圆角边框)
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-y>'] = cmp.mapping.confirm({ select = true }),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
          { name = 'path' },
        }),
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })
      -- 命令行补全 (: 前缀)
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' },
        }, {
          { name = 'cmdline' },
        }),
      })

      -- LSP: mason 管理 + lspconfig 默认配置
      require("mason").setup()
      local lspconfig = require("lspconfig")
      local on_attach = function(_, bufnr)
        local opts = { buffer = bufnr }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
      end
      require("mason-lspconfig").setup({
        -- 不强制安装任何 server: 用户可能有系统级 LSP, 避免大体积下载
        -- 空的 ensure_installed 时 mason-lspconfig 会配合 lspconfig 自动检测已安装的 server
        ensure_installed = {},
        -- 现代写法（mason-lspconfig 2.x，旧版 setup_handlers 已移除）：
        -- 给所有自动检测到的 server 统一挂 on_attach（gd/gr/K/重命名/代码操作键位）
        handlers = {
          function(server_name)
            if lspconfig[server_name] then
              lspconfig[server_name].setup({ on_attach = on_attach })
            end
          end,
        },
      })

      -- 🔴 nixpkgs 的 nvim-lspconfig 2.11.0 未内置 nil/nixd server 定义，
      --    需手动注册 nil（Nix LSP，已装于 PATH），现代写法 vim.lsp.config（nvim 0.11+）
      local nil_ok, nil_setup = pcall(vim.lsp.config, 'nil', {
        cmd = { 'nil' },
        root_markers = { 'flake.nix', 'default.nix', 'shell.nix' },
        filetypes = { 'nix' },
        on_attach = on_attach, -- 直接复用统一键位
      })
      if nil_ok then
        vim.lsp.enable('nil')
      end

      -- 手感插件: treesitter 文本对象 (af/if/ac/ic/ab/ib 选择, ]m/[m 跳转函数)
      -- nvim-treesitter 0.10+ 已移除 nvim-treesitter.configs, 改用插件自身的 setup API
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },  -- 类似 targets.vim: 选中后自动跳到下一个文本对象
        move = { set_jumps = true },
      })
      local ts_select = require("nvim-treesitter-textobjects.select")
      local ts_move = require("nvim-treesitter-textobjects.move")
      -- 选择文本对象 (x/o 模式): af/if 函数, ac/ic 类, ab/ib 代码块
      vim.keymap.set({ "x", "o" }, "af", function()
        ts_select.select_textobject("@function.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "if", function()
        ts_select.select_textobject("@function.inner", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ac", function()
        ts_select.select_textobject("@class.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ic", function()
        ts_select.select_textobject("@class.inner", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ab", function()
        ts_select.select_textobject("@block.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ib", function()
        ts_select.select_textobject("@block.inner", "textobjects")
      end)
      -- 跳转函数: ]m/[m 下一个/上一个函数开头, ]M/[M 下一个/上一个函数结尾
      vim.keymap.set({ "n", "x", "o" }, "]m", function()
        ts_move.goto_next_start("@function.outer", "textobjects")
      end)
      vim.keymap.set({ "n", "x", "o" }, "[m", function()
        ts_move.goto_previous_start("@function.outer", "textobjects")
      end)
      vim.keymap.set({ "n", "x", "o" }, "]M", function()
        ts_move.goto_next_end("@function.outer", "textobjects")
      end)
      vim.keymap.set({ "n", "x", "o" }, "[M", function()
        ts_move.goto_previous_end("@function.outer", "textobjects")
      end)

      -- 手感插件: surround 包裹 (nvim-surround, 默认映射无需配置)
      -- 用法: ysiw" 用引号包裹单词 / cs"' 把双引号换成单引号 / ds" 删除包裹

      -- 手感插件: git 增强 — blame 虚拟文本 (默认开启, gB 切换)
      require("gitblame").setup()
      vim.keymap.set('n', 'gB', ':GitBlameToggle<CR>', { desc = '切换 blame 显示' })
      -- 用法: gB 或 :GitBlameToggle 切换 blame; 虚拟文本默认显示作者/日期/摘要

      -- 手感插件: git diff/merge TUI (diffview-nvim)
      require("diffview").setup({})
      -- 用法: :DiffviewOpen 打开当前文件 diff / :DiffviewOpen main...HEAD 比较分支
    '';
  };
}
