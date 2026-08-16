# ============================================================
# cava.nix —— cava 音频可视化（Catppuccin Mocha 配色）
# 使用 home-manager 现代模块 programs.cava（ini 格式 settings）
# ============================================================
# 注意：cava 配置为 ini 格式（pkgs.formats.ini），hex 颜色值必须
#    带单引号作为字符串写入（'#f38ba8'），否则 cava 解析失败。
#    HM 自动写入 ~/.config/cava/config
{ pkgs, ... }:

{
  programs.cava = {
    enable = true;

    # ini 格式配置：顶层 attrset → 节（[section]）
    settings = {
      # [general] 通用
      general = {
        framerate = 60; # 刷新率 60fps
        bars = 20; # 条形数量
        autosens = 1; # 自动灵敏度
        lower_cutoff_freq = 50; # 低频截止 50Hz
      };

      # [color] Catppuccin Mocha 渐变配色
      color = {
        gradient = 1; # 启用渐变色
        # 渐变 4 色：红 → 紫 → 蓝 → 绿
        gradient_color_1 = "'#f38ba8'"; # red
        gradient_color_2 = "'#cba6f7'"; # mauve
        gradient_color_3 = "'#89b4fa'"; # blue
        gradient_color_4 = "'#a6e3a1'"; # green
        foreground = "'#89b4fa'"; # 默认前景（blue）
      };
    };
  };
}
