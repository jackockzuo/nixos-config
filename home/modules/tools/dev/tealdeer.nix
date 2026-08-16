# ============================================================
# tealdeer.nix —— tldr 手册（简洁命令示例）
# ============================================================
{ pkgs, ... }:

{
  programs.tealdeer = {
    enable = true;
    settings = {
      updates = {
        auto_update = true;
      };
    };
  };
}
