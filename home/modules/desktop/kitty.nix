_:

{
  # kitty 终端（programs.kitty 模块）
  # settings 内部用 lib.generators.toKeyValue 序列化（字符串不加引号、布尔转 yes/no）
  programs.kitty = {
    enable = true;

    # ================= 字体 =================
    font = {
      name = "Maple Mono NF CN";
      size = 11.5;
    };

    settings = {
      # 透明度 / 毛玻璃
      # 🔴 现代写法（niri v26.04 + kitty #9534）：background_blur 经 ext-background-effect 协议
      #    向合成器请求背景模糊，niri 26.04 原生支持（kitty ≥ 0.46.2）
      #    仅当 background_opacity < 1 时生效(REF:2026-08-kitty-blur)
      background_blur = "1";
      # 背景透明度 0.8：毛玻璃明显但不糊文字（与 background_blur 配合）
      background_opacity = "0.8";
      dynamic_background_opacity = "yes";
      hide_window_decorations = "yes";
      window_padding_width = "12";

      # 光标
      cursor_shape = "beam";
      cursor_blink_interval = "0.5";

      # 颜色由 catppuccin.kitty 注入（themeFile = Catppuccin-Mocha，含基础色 + 16 色）

      # 交互体验
      # 选中即复制到剪贴板
      copy_on_select = "clipboard";
      scrollback_lines = "10000";

      # 标签栏
      tab_bar_style = "powerline";
      tab_bar_min_tabs = "2";
      active_tab_foreground = "#11111b";
      active_tab_background = "#cba6f7";
      inactive_tab_foreground = "#cdd6f4";
      inactive_tab_background = "#313244";
      tab_bar_background = "#11111b";

      # 字体连字（Maple Mono NF CN 支持连字，kitty 默认开启，显式声明不关闭）
      disable_ligatures = "never";
    };

    # 快捷键（仅新增映射，不覆盖默认）
    keybindings = {
      "ctrl+shift+t" = "new_tab_with_cwd";
      "ctrl+shift+enter" = "new_window_with_cwd";
      "ctrl+shift+h" = "previous_window";
      "ctrl+shift+l" = "next_window";
    };
  };

  # 会话文件：kitty --session work 一键打开工作区
  # 配合 tools/fish.nix 的 ks 别名使用
  # 注意：kitty --session 相对路径直接相对 ~/.config/kitty 解析
  xdg.configFile."kitty/work".text = ''
    # 工作会话：2 个窗口左右分屏 + 顶部标签栏
    new_tab work
    launch --cwd=~ fish
    launch --cwd=~ --location=vsplit btop
    launch --cwd=~ --location=hsplit fish
    layout splits
  '';
}
