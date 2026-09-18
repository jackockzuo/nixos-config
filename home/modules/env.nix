# env.nix —— 用户级环境变量（sessionVariables）
# 职责：平台无关的用户会话变量（Wayland/桌面/工具链）的唯一落点
# 输入法变量单一来源：系统层 modules/locale.nix + home/modules/desktop/niri.nix（见 STANDARDS §4）
# 主机专属变量（第三方/端口）→ hosts/<machine>/hm.nix（STANDARDS §0.5）
# ============================================================
_:

{
  home.sessionVariables = {
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    QT_QPA_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "Niri";

    PASSWORD_STORE = "gnome-listsecret";

    # man 手册分页（bat 渲染）
    MANPAGER = "bat --paging=never";
    MANROFFOPT = "-c";
  };
}
