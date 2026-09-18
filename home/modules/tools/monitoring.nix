# monitoring.nix —— 系统监控（btop/cava）+ 磁盘/日志/网络排障 CLI
# ============================================================
{ pkgs, ... }:

{
  # btop：进程/CPU/内存/网络监控
  # 配色由 catppuccin.btop 注入（theme 文件 + color_theme，见 home/modules/theme/）
  programs.btop = {
    enable = true;

    # btop.conf（HM 自动序列化为 key = value 格式）
    settings = {
      theme_background = false; # 透明背景（配合 kitty 毛玻璃）
      vim_keys = false;
      update_ms = 2000;
      graph_symbol = "block";
      shown_boxes = "cpu mem net proc";
    };
  };
  # 🔴 btop 首次运行自动生成默认 btop.conf → 不设 force 会 checkLinkTargets 报错
  xdg.configFile."btop/btop.conf".force = true;

  # cava：音频可视化
  # 配色由 catppuccin.cava 注入（theme = "catppuccin"）
  programs.cava = {
    enable = true;
    settings = {
      general = {
        framerate = 60;
        bars = 20;
        autosens = 1;
        lower_cutoff_freq = 50;
      };
    };
  };

  # 监控/排障 CLI（纯安装，无 HM 模块）
  home.packages = with pkgs; [
    duf # 磁盘空间
    dust # 空间树状图
    lnav # 日志文件/日志的 TUI 查看器（时间线+高亮+SQL 过滤）
    bandwhich # 实时网络带宽按进程归因
  ];
}
