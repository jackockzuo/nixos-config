{ ... }:

{
  # bat：cat 增强（语法高亮 + 分页器）
  # 合并自旧 tools/shell.nix（enable）与 terminal-theme.nix（Catppuccin Mocha 主题）
  # 注：MANPAGER = "bat --paging=never" 在 env.nix 管理（man 手册页走 bat 渲染）
  programs.bat = {
    enable = true;
    config = {
      # bat >= 0.24 内置 Catppuccin-Mocha 主题（来自 catppuccin/sublime-text），无需下载
      theme = "Catppuccin-Mocha";
      # 不分页，直接输出（配合交互式终端/管道）
      paging = "never";
    };
  };
}
