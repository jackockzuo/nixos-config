_:

{
  # fzf：模糊查找（Ctrl-T 文件选择 / Alt-C 目录跳转）
  # 合并自旧 tools/shell.nix（enable + fish 集成）与 terminal-theme.nix（Catppuccin Mocha 配色 + Ctrl-R 让位）
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
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
}
