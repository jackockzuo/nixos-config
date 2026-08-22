# ============================================================
# direnv.nix —— direnv 目录环境（进入目录自动加载环境）
# ============================================================
# 🔴 fish 集成改用 type -q 守卫（2026-08-18，Distrobox 容器报错修复）：
#   HM 的 enableFishIntegration 无条件执行 store 里的 direnv hook fish，
#   容器内（Distrobox 挂载 $HOME）加载宿主 fish 配置时报 Unknown command。
#   守卫：type -q 存在 → 宿主正常启用；不存在 → 静默跳过。
#   保留 HM 原有的 functions -q 幂等检查（防重复挂载）。
{ lib, ... }:

{
  programs.direnv = {
    enable = true;
    # 集成交给下方 lib.mkAfter 守卫块（type -q direnv），关闭 HM 无条件生成
    enableFishIntegration = false;
    nix-direnv.enable = true;
  };

  programs.fish.interactiveShellInit = lib.mkAfter ''
    if type -q direnv
        if not functions -q __direnv_export_eval
            direnv hook fish | source
        end
    end
  '';
}
