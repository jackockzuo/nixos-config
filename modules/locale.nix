# ============================================================
# locale.nix —— 语言/时区/输入法
# 职责：locale 生成、时区、双系统时钟、fcitx5 输入法
# ============================================================
{ pkgs, lib, ... }:

{
  i18n = {
    # 必须显式声明 zh_CN locale：niri 会话设置了 LANG=zh_CN.UTF-8
    defaultLocale = "zh_CN.UTF-8";
    supportedLocales = [
      "zh_CN.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "C.UTF-8/UTF-8"
    ];

    # 输入法：fcitx5（系统级）
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        # 必须 override rimeDataPkgs 加入 rime-ice，否则 "missing input schema: rime_ice"
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
  time.timeZone = "Asia/Shanghai";
  time.hardwareClockInLocalTime = true;

  environment.sessionVariables = {
    # IM 变量单一来源（会话作用域，见 STANDARDS §4 双作用域）
    # Qt6 Wayland 双通道：QT_IM_MODULES="wayland;fcitx" 必须放系统层
    # niri 的 environment 不传给 systemd 启动的应用（DMS 等）(REF:2026-08-21-fcitx5-gtk)
    QT_IM_MODULES = "wayland;fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    # kitty 只认 ibus 值，fcitx5 提供 ibus 协议兼容 (REF:2026-08-21-fcitx5-gtk)
    GLFW_IM_MODULE = "ibus";
  };
  # Wayland 原生 GTK3/4 走 text-input-v3，不设全局 GTK_IM_MODULE
  # NixOS fcitx5 模块会写死 "fcitx"，必须 mkForce "" 覆盖 (REF:2026-08-21-fcitx5-gtk)
  environment.variables.GTK_IM_MODULE = lib.mkForce "";
}
