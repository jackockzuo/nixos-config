# ============================================================
# lazygit.nix —— git TUI（Catppuccin Mocha 主题）
# ============================================================
{ pkgs, ... }:

{
  # lazygit：Catppuccin Mocha 主题（git TUI）
  programs.lazygit = {
    enable = true;
    settings = {
      gui.theme = {
        selectedLineBgColor = [ "#313244" ];
        activeBorderColor = [ "#89b4fa" "bold" ];
        inactiveBorderColor = [ "#585b70" ];
        optionsFgColor = [ "#89b4fa" ];
        selectedRangeBgColor = [ "#313244" ];
        cherryPickedCommitBgColor = [ "#45475a" ];
        cherryPickedCommitFgColor = [ "#cba6f7" ];
        unstagedChangesColor = [ "#f38ba8" ];
        defaultFgColor = [ "#cdd6f4" ];
        searchingActiveBorderColor = [ "#f9e2af" ];
      };
    };
  };
}
