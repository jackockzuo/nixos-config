# ============================================================
# monitoring.nix —— 系统监控（并入 monitoring/{btop,cava}）
# 职责：进程监控(btop, Catppuccin Mocha) / 音频可视化(cava)
# ============================================================
_:

{
  # ---- btop：进程/CPU/内存/网络监控 ----
  # 🔴 btop 0.27+ 主题语法从旧 `theme_xxx=#hex` 改为新 `theme[xxx]="#hex"`，
  #    旧格式在当前 btop 1.4.7 上完全失效；themes 选项原样写入
  #    ~/.config/btop/themes/catppuccin_mocha.theme
  programs.btop = {
    enable = true;

    # btop.conf（HM 自动序列化为 key = value 格式）
    settings = {
      color_theme = "catppuccin_mocha";
      theme_background = false; # 透明背景（配合 kitty 毛玻璃）
      vim_keys = false;
      update_ms = 2000;
      graph_symbol = "block";
      shown_boxes = "cpu mem net proc";
    };

    themes.catppuccin_mocha = ''
      # Catppuccin Mocha（btop 1.x 新格式）
      theme[main_bg]="#11111b"
      theme[main_fg]="#cdd6f4"
      theme[title]="#cdd6f4"
      theme[hi_fg]="#a6adc8"
      theme[selected_bg]="#313244"
      theme[selected_fg]="#f5c2e7"
      theme[inactive_fg]="#6c7086"
      theme[graph_text]="#a6adc8"
      theme[meter_bg]="#313244"
      theme[proc_misc]="#cba6f7"
      theme[cpu_box]="#f9e2af"
      theme[mem_box]="#a6e3a1"
      theme[net_box]="#94e2d5"
      theme[proc_box]="#f38ba8"
      theme[div_line]="#313244"
      theme[temp_start]="#f9e2af"
      theme[temp_mid]="#fab387"
      theme[temp_end]="#f38ba8"
      theme[cpu_start]="#f9e2af"
      theme[cpu_mid]="#fab387"
      theme[cpu_end]="#f38ba8"
      theme[free_start]="#a6e3a1"
      theme[free_mid]="#94e2d5"
      theme[free_end]="#89b4fa"
      theme[cached_start]="#94e2d5"
      theme[cached_mid]="#89b4fa"
      theme[cached_end]="#cba6f7"
      theme[available_start]="#a6e3a1"
      theme[available_mid]="#94e2d5"
      theme[available_end]="#89b4fa"
      theme[used_start]="#f9e2af"
      theme[used_mid]="#fab387"
      theme[used_end]="#f38ba8"
      theme[download_start]="#89b4fa"
      theme[download_mid]="#cba6f7"
      theme[download_end]="#f5c2e7"
      theme[upload_start]="#94e2d5"
      theme[upload_mid]="#89b4fa"
      theme[upload_end]="#cba6f7"
      theme[process_start]="#f38ba8"
      theme[process_mid]="#fab387"
      theme[process_end]="#f9e2af"
    '';
  };
  # 🔴 btop 首次运行自动生成默认 btop.conf → 不设 force 会 checkLinkTargets 报
  #    "would be clobbered"，连带其他 HM 配置全部无法部署
  xdg.configFile."btop/btop.conf".force = true;

  # ---- cava：音频可视化（Catppuccin Mocha 渐变）----
  # 注意：cava 配置为 ini 格式（pkgs.formats.ini），hex 颜色值必须带单引号写字符串
  programs.cava = {
    enable = true;
    settings = {
      general = {
        framerate = 60;
        bars = 20;
        autosens = 1;
        lower_cutoff_freq = 50;
      };
      color = {
        gradient = 1;
        gradient_color_1 = "'#f38ba8'"; # red
        gradient_color_2 = "'#cba6f7'"; # mauve
        gradient_color_3 = "'#89b4fa'"; # blue
        gradient_color_4 = "'#a6e3a1'"; # green
        foreground = "'#89b4fa'";
      };
    };
  };
}
