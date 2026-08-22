# ============================================================
# fzf.nix —— fzf 模糊查找（Ctrl-T 文件选择 / Alt-C 目录跳转）
# ============================================================
# 合并自旧 tools/shell.nix（enable + fish 集成）与 terminal-theme.nix
# （Catppuccin Mocha 配色 + Ctrl-R 让位）
#
# 🔴 fish 集成改用 type -q 守卫（2026-08-18，Distrobox 容器报错修复）：
#   HM 的 enableFishIntegration 会无条件执行 fzf --fish（store 绝对路径），
#   容器内（Distrobox 挂载 $HOME）加载宿主 fish 配置时 fzf 输出含高层 return、
#   fish 3.3.1 报 "return outside of function definition" + Unknown command。
#   守卫：type -q 存在 → 宿主正常启用；不存在 → 静默跳过。
#   ⚠️ 容器内 fish 是 3.3.1，必须用 type -q（command -q 是 fish 3.4+ 才有）。
{ lib, ... }:

{
  # fzf：模糊查找（Ctrl-T 文件选择 / Alt-C 目录跳转）
  programs.fzf = {
    enable = true;
    # 集成交给下方 lib.mkAfter 守卫块（type -q fzf），关闭 HM 无条件生成
    enableFishIntegration = false;
    # Catppuccin Mocha 配色（bg = "-1" 保持终端背景透明）
    colors = {
      "fg" = "#cdd6f4";
      "bg" = "-1"; # transparent
      "hl" = "#f38ba8";
      "fg+" = "#cdd6f4";
      "bg+" = "#313244";
      "hl+" = "#f38ba8";
      "info" = "#cba6f7";
      "prompt" = "#cba6f7";
      "pointer" = "#f5c2e7";
      "marker" = "#f5c2e7";
      "spinner" = "#f5c2e7";
      "header" = "#f9e2af";
    };
    # 🔴 历史搜索 Ctrl-R 让给 atuin（atuin 已启用 fish 集成接管 Ctrl-R），
    # 空 command 禁用 fzf 的 Ctrl-R 绑定，消除两个历史管理器的键位冲突
    # （这也是 HM 模块官方推荐的让位方式）
    historyWidget.command = "";
  };

  programs.fish.interactiveShellInit = lib.mkAfter ''
    if type -q fzf
        fzf --fish | source
    end
  '';
}
