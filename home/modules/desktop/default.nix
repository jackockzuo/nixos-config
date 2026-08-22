# ============================================================
# desktop/default.nix —— 桌面环境配置聚合（定位地图）
# 架构量化规则（STANDARDS §2）：一文件一领域、目录 ≤2 层、
# 无预留空壳；每行 import 带职责注释
# ============================================================
{ pkgs, ... }:

{
  imports = [
    ./niri.nix # 合成器配置（source/niri 全套）
    ./kitty.nix # 终端
    ./fcitx5.nix # 输入法（fcitx5 + rime 雾凇）
    ./dms.nix # 桌面壳（DankMaterialShell）
    ./appearance.nix # fastfetch/字体渲染/GTK 主题/光标
    ./misc.nix # 桌面杂项合并（swaync/portal/mpv/satty/mimeapps）
  ];

  # 桌面环境必需的 CLI 工具（nix 管理；截图/剪贴板/U盘挂载）
  home.packages = with pkgs; [
    grim # 截图（niri 绑定调用）
    slurp # 区域选择
    wl-clipboard # wl-copy/wl-paste 剪贴板
    cliphist # 历史剪贴板
    udiskie # U盘自动挂载
    fastfetch # 系统信息（终端启动显示）
    eza # ls 增强
    bat # cat 增强
    fzf # 模糊搜索
    zoxide # cd 增强
  ];
}
