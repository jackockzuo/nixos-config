# ============================================================
# locale.nix —— 语言/时区/输入法
# 职责：locale 生成、时区、双系统时钟、fcitx5 输入法
# 修改：语言/时区/输入法方案 → 改这里
# 关联：home-manager/desktop/fcitx5.nix（用户级外观/词库）
# ============================================================
{ pkgs, ... }:

{
  i18n = {
    # ============ 语言与地区 ============
    # 🔴 必须显式声明并生成 zh_CN locale：niri 会话设置了 LANG=zh_CN.UTF-8
    # （source/niri/config.kdl），若不生成，bash 启动报
    # "setlocale: LC_COLLATE: cannot change locale (zh_CN.UTF-8)"。
    # defaultLocale 会自动加入 supportedLocales，但显式写出更清晰。
    defaultLocale = "zh_CN.UTF-8";
    supportedLocales = [
      "zh_CN.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "C.UTF-8/UTF-8"
    ];

    # ============ 输入法：fcitx5（系统级）============
    # 注意：.enable/.type 是新式写法（旧 .enabled 已弃用）
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        # 🔴 必须 override fcitx5-rime 的 rimeDataPkgs 加入 rime-ice！
        # nixpkgs 默认 rimeDataPkgs 只有 [ rime-data ]（基础包，不含 rime_ice schema），
        # 导致 fcitx5-rime 的共享数据目录 share/rime-data 里没有 rime_ice.schema.yaml，
        # rime 引擎启动部署时报 "missing input schema: rime_ice" → 输入法失效。
        # 之前 HM 用 xdg.dataFile 往用户目录塞 symlink 是错误方案：
        # rime 的 SyncUserData 部署任务会把共享目录里不存在的文件从用户目录删除。
        (fcitx5-rime.override {
          rimeDataPkgs = [
            pkgs.rime-data
            pkgs.rime-ice
          ];
        })
        rime-ice
        catppuccin-fcitx5
        fcitx5-gtk
        qt6Packages.fcitx5-chinese-addons
      ];
    };
  };
  # 时区：上海（CST, UTC+8）
  time.timeZone = "Asia/Shanghai";
  # 🔴 双系统时钟修复：Windows 按本地时间读 RTC，Linux 按 UTC。
  # 不设的话，两系统切换后时钟各错 8 小时。设 true 让 Linux 也按本地时间读 RTC。
  time.hardwareClockInLocalTime = true;
  environment.sessionVariables = {
    # 现代写法（fcitx wiki 2025-09）：不设全局 GTK_IM_MODULE —— Wayland 原生
    # GTK3/4 自动走 text-input-v3，全局设置反而触发候选框闪烁；
    # X11/XWayland 应用用 gtk-im-module=fcitx（见 home/modules/desktop/fcitx5.nix）。
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    # 🔴 kitty 源码（glfw/ibus_glfw.c）只认 ibus 值，fcitx5 提供 ibus 协议兼容；
    # 这一条是 Kitty 专属的关键变量，缺少它 Kitty 一定无法激活输入法
    GLFW_IM_MODULE = "ibus";
  };
}
