# ============================================================
# direnv.nix —— direnv 目录环境（进入目录自动加载环境）
# ============================================================
_:

{
  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };
}
