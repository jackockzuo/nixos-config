{ ... }:

{
  xdg.configFile."kitty/kitty.conf".text = ''
    font_family      Maple Mono NF CN
    font_size        11.5

    background_opacity 0.85
    dynamic_background_opacity yes
    hide_window_decorations yes
    window_padding_width 12

    cursor_shape beam

    foreground #cdd6f4
    background #1e1e2e
    selection_foreground #1e1e2e
    selection_background #f5e0dc
    color0 #45475a
    color1 #f38ba8
    color2 #a6e3a1
    color3 #f9e2af
    color4 #89b4fa
    color5 #f5c2e7
    color6 #94e2d5
    color7 #bac2de
  '';
}
