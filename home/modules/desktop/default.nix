# ============================================================
# desktop/default.nix —— 桌面环境配置聚合
# ============================================================
{ pkgs, ... }:

let
  # Firefox Wayland IM wrapper：全局 GTK_IM_MODULE=fcitx 会双通道冲突 → 只对 firefox 覆盖为 wayland
  firefox = pkgs.symlinkJoin {
    name = "firefox-wayland-im";
    paths = [ pkgs.firefox ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/firefox \
        --set GTK_IM_MODULE wayland
    '';
  };
in

{
  imports = [
    ./niri.nix # 合成器核心
    ./niri-binds.nix # 合成器快捷键
    ./niri-rules.nix # 窗口/图层规则
    ./hyprlock.nix # 锁屏
    ./kitty.nix # 终端
    ./fcitx5.nix # 输入法
    ./dms.nix # 桌面壳
    ./appearance.nix # 字体渲染/GTK 主题/光标
    ./misc.nix # 桌面杂项（swaync/portal/mpv/satty/mimeapps）
  ];

  # 桌面环境工具与应用
  home.packages = with pkgs; [
    # GUI 应用
    firefox # Wayland IM wrapper
    google-chrome
    nautilus # 文件管理
    imv # 图片查看
    localsend # 局域网传输

    # 桌面 CLI 工具
    grim # 截图
    slurp # 区域选择
    wl-clipboard # 剪贴板
    cliphist # 历史剪贴板
    udiskie # U盘自动挂载
    eza # ls 增强
    bat # cat 增强
    fzf # 模糊搜索
    zoxide # cd 增强
  ];
}
