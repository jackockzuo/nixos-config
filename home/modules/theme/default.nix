# ============================================================
# theme/default.nix —— 主题领域聚合（定位地图）
# 两层：静态 catppuccin 端口 / 外观资产（catppuccin 无端口部分）
# DMS 外壳的壁纸取色由 DMS 自带 dynamic theming 管理（settings.json，不在此）
# 不在这里放机器专属（显示器形态→hosts/<machine>/hm.nix）或程序自身配置
# ============================================================
{ ... }:

{
  imports = [
    ./catppuccin.nix # catppuccin/nix 全局（flavor/accent + autoEnable 端口开关）
    ./appearance.nix # GTK/图标回退/光标/字体渲染/fastfetch/Qt（catppuccin 无端口的资产）
  ];
}
