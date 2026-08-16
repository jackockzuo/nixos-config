# ============================================================
# desktop/default.nix —— 桌面环境配置聚合
# 原则：二进制（niri/kitty/fcitx5 等）由 NixOS 系统层安装，
#       HM 只管理配置文件
# 每个子模块独立关注点，可按需增删
# 新增 → 新建 <关注点>.nix 并在此加一行；预留 → 取消注释
# ============================================================
{ pkgs, ... }:

{
  imports = [
    ./niri.nix # 合成器配置（source/niri 全套）
    ./kitty.nix # 终端
    ./fcitx5.nix # 输入法（fcitx5 + rime 雾凇）
    ./dms.nix # 桌面壳（DankMaterialShell）
    ./swaync.nix # 通知（毛玻璃）
    ./appearance.nix # fastfetch/字体渲染/GTK 主题/光标
    ./screenshot.nix # satty 截图标注
    ./mpv.nix # 视频播放
    ./filemanager.nix # 默认应用 (mimeapps)
    ./portal.nix # xdg-desktop-portal

    # ---- 🔮 预留模块（需要时取消注释）----
    # ./media.nix # 音乐/流媒体（Spotify/ncmpcpp）
    # ./design.nix # 设计创作（GIMP/Krita/Blender）
    # ./games.nix # 游戏（Steam/Lutris/Heroic）
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
