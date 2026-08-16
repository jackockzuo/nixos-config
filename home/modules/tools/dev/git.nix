# ============================================================
# git.nix —— git 版本控制
# ============================================================
{ pkgs, ... }:

{
  # 开发者工具配置
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "ran";
        email = "jackocksmic@outlook.com";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };
}
