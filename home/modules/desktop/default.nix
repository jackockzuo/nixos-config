# ============================================================
# desktop/default.nix —— 桌面环境配置聚合（定位地图）
# ============================================================
{ ... }:

{
  imports = [
    ./niri.nix # 合成器核心
    ./niri-animations.nix # 合成器动画（spring）
    ./niri-binds.nix # 合成器快捷键
    ./niri-rules.nix # 窗口/图层规则
    ./hyprlock.nix # 锁屏
    ./kitty.nix # 终端
    ./fcitx5.nix # 输入法
    ./dms.nix # 桌面壳
    ./misc.nix # 桌面杂项（swaync/portal/mpv/satty/mimeapps）
    ./packages.nix # 桌面工具与应用（纯安装）
  ];
}
