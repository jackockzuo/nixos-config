# ============================================================
# btop.nix —— btop 系统监控（Catppuccin Mocha 主题）
# 使用 home-manager 现代模块 programs.btop（settings + themes）
# ============================================================
# 🔴 关键修复：btop 0.27+ 将主题语法从旧格式 `theme_xxx=#hex` 改为
#    新格式 `theme[xxx]="#hex"`；旧主题文件（btop <=0.27 语法）在
#    当前安装的 btop 1.4.7 上完全失效（颜色不生效）。
#    本文件改用新语法重写主题，恢复 Catppuccin Mocha 配色。
#    themes 选项内容会原样写入 ~/.config/btop/themes/catppuccin_mocha.theme
{ pkgs, ... }:

{
  programs.btop = {
    enable = true;

    # btop.conf 配置（HM 自动序列化为 key = value 格式）
    settings = {
      color_theme = "catppuccin_mocha"; # 对应下方 themes 定义的主题名
      theme_background = false; # 透明背景（配合 kitty 92% 透明度）
      vim_keys = false; # 默认按键
      update_ms = 2000; # 刷新间隔 2 秒
      graph_symbol = "block"; # 实心方块图形
      shown_boxes = "cpu mem net proc"; # 显示：CPU/内存/网络/进程
    };

    # Catppuccin Mocha 主题（新语法 theme[xxx]，btop 1.x 必须）
    themes.catppuccin_mocha = ''
      # Catppuccin Mocha（btop 1.x 新格式主题语法）
      theme[main_bg]="#11111b"          # 主背景（原 theme_background）
      theme[main_fg]="#cdd6f4"          # 主前景（原 theme_foreground）
      theme[title]="#cdd6f4"            # 标题文字
      theme[hi_fg]="#a6adc8"            # 高亮辅助文字（subtext1）
      theme[selected_bg]="#313244"      # 选中项背景（原 theme_choice）
      theme[selected_fg]="#f5c2e7"      # 选中项前景（pink）
      theme[inactive_fg]="#6c7086"      # 非活跃元素（overlay1）
      theme[graph_text]="#a6adc8"       # 图形刻度文字
      theme[meter_bg]="#313244"         # 仪表底色（surface0）
      theme[proc_misc]="#cba6f7"        # 进程杂项（mauve，原 theme_gpu）
      theme[cpu_box]="#f9e2af"          # CPU 边框（yellow，原 theme_cpu）
      theme[mem_box]="#a6e3a1"          # 内存边框（green，原 theme_mem）
      theme[net_box]="#94e2d5"          # 网络边框（teal，原 theme_net）
      theme[proc_box]="#f38ba8"         # 进程边框（red，原 theme_proc）
      theme[div_line]="#313244"         # 分隔线（surface0，原 theme_empty）
      theme[temp_start]="#f9e2af"       # 温度低（yellow）
      theme[temp_mid]="#fab387"         # 温度中（peach）
      theme[temp_end]="#f38ba8"         # 温度高（red）
      theme[cpu_start]="#f9e2af"        # CPU 负载低（yellow）
      theme[cpu_mid]="#fab387"          # CPU 负载中（peach）
      theme[cpu_end]="#f38ba8"          # CPU 负载高（red）
      theme[free_start]="#a6e3a1"       # 空闲内存低段（green）
      theme[free_mid]="#94e2d5"         # 空闲内存中段（teal）
      theme[free_end]="#89b4fa"         # 空闲内存高段（blue）
      theme[cached_start]="#94e2d5"     # 缓存低段（teal）
      theme[cached_mid]="#89b4fa"       # 缓存中段（blue）
      theme[cached_end]="#cba6f7"       # 缓存高段（mauve）
      theme[available_start]="#a6e3a1"  # 可用内存低段（green）
      theme[available_mid]="#94e2d5"    # 可用内存中段（teal）
      theme[available_end]="#89b4fa"    # 可用内存高段（blue）
      theme[used_start]="#f9e2af"       # 已用内存低段（yellow）
      theme[used_mid]="#fab387"         # 已用内存中段（peach）
      theme[used_end]="#f38ba8"         # 已用内存高段（red）
      theme[download_start]="#89b4fa"   # 下载速率低（blue）
      theme[download_mid]="#cba6f7"     # 下载速率中（mauve）
      theme[download_end]="#f5c2e7"     # 下载速率高（pink）
      theme[upload_start]="#94e2d5"     # 上传速率低（teal）
      theme[upload_mid]="#89b4fa"       # 上传速率中（blue）
      theme[upload_end]="#cba6f7"       # 上传速率高（mauve）
      theme[process_start]="#f38ba8"    # 进程占用低（red）
      theme[process_mid]="#fab387"      # 进程占用中（peach）
      theme[process_end]="#f9e2af"      # 进程占用高（yellow）
    '';
  };
  # 🔴 btop 首次运行会自动生成默认 btop.conf（用户 ~/.config/btop/btop.conf 已存在），
  #    不设 force 会导致 home-manager activation 整体失败（checkLinkTargets 报
  #    "would be clobbered"），连带 starship 等其他所有 HM 配置全部无法部署
  xdg.configFile."btop/btop.conf".force = true;
}
