_:

{
  # ================= kitty 终端（现代写法：programs.kitty 模块） =================
  # 由 HM programs.kitty 模块生成 ~/.config/kitty/kitty.conf（不再手写整份 conf）：
  # - settings 内部用 lib.generators.toKeyValue 序列化，字符串原样输出不加引号、
  #   布尔值转 yes/no，按声明顺序写入；值为字符串/数字/布尔皆可
  # - font 选项生成 font_family / font_size（优先级高于 settings）
  # - keybindings 选项生成 map 行，仅新增映射、不覆盖默认
  programs.kitty = {
    enable = true;

    # ================= 字体 =================
    font = {
      name = "Maple Mono NF CN";
      size = 11.5;
    };

    settings = {
      # ================= 透明度 / 毛玻璃 =================
      # 🔴 现代写法（niri v26.04 官方发布说明 + kitty #9534）：
      #   background_blur 经 ext-background-effect 协议向合成器请求背景模糊，
      #   niri 26.04 原生支持（kitty ≥ 0.46.2，本机 0.48.2）。
      #   ⚠️ 仅当 background_opacity < 1 时生效；模糊形状由 kitty 请求（矩形），
      #   圆角由 niri 侧 geometry-corner-radius 负责（见 blur.kdl）。
      #   kitty 的 background_opacity 只作用于默认背景色 cell——
      #   vim 状态栏/编辑器主题自带背景色的区域保持不透明（对终端是特性）。
      background_blur = "1";
      # 🔴 背景透明度 0.8：毛玻璃明显但不糊文字（与 background_blur 配合）。
      #   调更低（0.5-0.6）= 更透；调更高（0.9+）= 更接近不透明。
      background_opacity = "0.8";
      dynamic_background_opacity = "yes";
      hide_window_decorations = "yes";
      window_padding_width = "12";

      # ================= 光标 =================
      cursor_shape = "beam";
      cursor_blink_interval = "0.5";

      # ================= 颜色（Catppuccin Mocha 完整 16 色） =================
      # 基础色
      foreground = "#cdd6f4";
      background = "#1e1e2e";
      cursor_text_color = "#1e1e2e";
      selection_foreground = "#1e1e2e";
      selection_background = "#f5e0dc";

      # 普通色（color0-7）
      color0 = "#45475a";
      color1 = "#f38ba8";
      color2 = "#a6e3a1";
      color3 = "#f9e2af";
      color4 = "#89b4fa";
      color5 = "#f5c2e7";
      color6 = "#94e2d5";
      color7 = "#bac2de";

      # 亮色（color8-15）—— 补齐后 git diff / fzf / htop / eza 高亮恢复正常
      color8 = "#585b70";
      color9 = "#f38ba8";
      color10 = "#a6e3a1";
      color11 = "#f9e2af";
      color12 = "#89b4fa";
      color13 = "#f5c2e7";
      color14 = "#94e2d5";
      color15 = "#a6adc8";

      # ================= 交互体验 =================
      # 选中即复制到剪贴板
      copy_on_select = "clipboard";
      scrollback_lines = "10000";

      # ================= 标签栏 =================
      tab_bar_style = "powerline";
      tab_bar_min_tabs = "2";
      active_tab_foreground = "#11111b";
      active_tab_background = "#cba6f7";
      inactive_tab_foreground = "#cdd6f4";
      inactive_tab_background = "#313244";
      tab_bar_background = "#11111b";

      # ================= 字体连字 =================
      # Maple Mono NF CN 支持连字，kitty 默认开启，这里显式声明不关闭
      disable_ligatures = "never";
    };

    # ================= 快捷键（仅新增映射，不覆盖默认） =================
    keybindings = {
      "ctrl+shift+t" = "new_tab_with_cwd";
      "ctrl+shift+enter" = "new_window_with_cwd";
      "ctrl+shift+h" = "previous_window";
      "ctrl+shift+l" = "next_window";
    };
  };

  # ================= 会话文件 =================
  # 会话文件：kitty --session work 一键打开工作区（fish + btop + fish 三窗口）；
  # 配合 tools/terminal/fish.nix 的 ks 别名使用
  # 注意：kitty 的 --session 相对路径直接相对 ~/.config/kitty 解析（已验证 0.48.2），
  # 不会自动去 sessions/ 子目录找，故文件放在配置根目录，无扩展名
  # （会话文件无 HM 模块支持，继续用 xdg.configFile 声明）
  xdg.configFile."kitty/work".text = ''
    # 工作会话：2 个窗口左右分屏 + 顶部标签栏
    new_tab work
    launch --cwd=~ fish
    launch --cwd=~ --location=vsplit btop
    launch --cwd=~ --location=hsplit fish
    layout splits
  '';
}
