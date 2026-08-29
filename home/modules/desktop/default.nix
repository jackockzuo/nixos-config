# ============================================================
# desktop/default.nix —— 桌面环境配置聚合（定位地图）
# 架构量化规则（STANDARDS §2）：一文件一领域、目录 ≤2 层、
# 无预留空壳；每行 import 带职责注释
# ============================================================
{ pkgs, ... }:

let
  # Firefox 单独走 Wayland text-input 协议（原 modules/packages.nix，2026-08-29 随 GUI 下放用户层）
  # 🔴 原因：Firefox 原生 Wayland 运行（MOZ_ENABLE_WAYLAND=1），全局 GTK_IM_MODULE=fcitx
  #    会强制它额外加载 fcitx5-gtk 的 dbus 通道 → 双通道冲突 → 候选框（皮肤）不显示。
  #    见 fcitx5 官方 FAQ：Wayland 原生 GTK 应用应走 text-input 协议。
  #    这里只对 firefox 覆盖为 wayland，XWayland 应用（QQ 等）仍用全局 fcitx。
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
    ./niri.nix # 合成器核心（wayland.windowManager.niri 模块，环境/输入/布局/动画/启动项）
    ./niri-binds.nix # 合成器快捷键（settings.binds）
    ./niri-rules.nix # 窗口/图层规则 + 输出 + 毛玻璃（settings._children）
    ./hyprlock.nix # 锁屏（programs.hyprlock，原 source/niri/hyprlock*.conf 内联）
    ./kitty.nix # 终端
    ./fcitx5.nix # 输入法（fcitx5 + rime 雾凇）
    ./dms.nix # 桌面壳（DankMaterialShell）
    ./appearance.nix # fastfetch/字体渲染/GTK 主题/光标
    ./misc.nix # 桌面杂项合并（swaync/portal/mpv/satty/mimeapps）
  ];

  # 桌面环境工具与应用（nix 管理）
  # 🔴 2026-08-29：GUI 应用从系统层下放至此（niri 会话 PATH 含 ~/.nix-profile/bin，
  #    spawn/binds/mimeapps 均可见）；mpv/satty 由 programs 模块自装（misc.nix）
  # 注：fastfetch 已由 programs.fastfetch 模块安装（appearance.nix），不重复
  home.packages = with pkgs; [
    # ---- 下放的 GUI 应用（原系统层 packages.nix）----
    firefox # Wayland IM wrapper（上方 let，见 fcitx5 双通道说明）
    google-chrome
    nautilus # 文件管理（mimeapps inode/directory）
    imv # 图片查看（mimeapps image/*）
    localsend # 局域网传输
    btrfs-assistant # snapper 快照 GUI（rule.kdl 浮动窗口规则）

    # ---- 桌面 CLI 工具 ----
    grim # 截图（niri 绑定调用）
    slurp # 区域选择
    wl-clipboard # wl-copy/wl-paste 剪贴板
    cliphist # 历史剪贴板
    udiskie # U盘自动挂载
    eza # ls 增强
    bat # cat 增强
    fzf # 模糊搜索
    zoxide # cd 增强
  ];
}
