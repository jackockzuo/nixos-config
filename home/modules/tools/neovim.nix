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
    '';
  };
}
