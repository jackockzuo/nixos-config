# ============================================================
# zoxide.nix —— zoxide 智能 cd（数据库记录目录使用频率）
# ============================================================
# 🔴 fish 集成改用 type -q 守卫（2026-08-18，Distrobox 容器报错修复）：
#   HM 的 enableFishIntegration 会无条件执行 store 里的 zoxide init fish，
#   容器内（Distrobox 挂载 $HOME）加载宿主 fish 配置时报 Unknown command。
#   守卫：type -q 存在 → 宿主正常启用；不存在 → 静默跳过。
#   ⚠️ 容器内 fish 是 3.3.1，必须用 type -q（command -q 是 fish 3.4+ 才有）。
{ lib, ... }:

{
  # zoxide：智能 cd（数据库记录目录使用频率，输入模糊片段直达高频目录）
  programs.zoxide = {
    enable = true;
    # 集成交给下方 lib.mkAfter 守卫块（type -q zoxide），关闭 HM 无条件生成
    enableFishIntegration = false;
  };

  programs.fish.interactiveShellInit = lib.mkAfter ''
    if type -q zoxide
        zoxide init fish | source
    end
  '';
}
