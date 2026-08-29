# ============================================================
# env.nix —— 用户级环境变量（sessionVariables）
# 职责：用户专属会话变量（Wayland/桌面/工具链）的唯一落点
# ⚠️ 输入法变量（QT_IM_MODULE/XMODIFIERS/SDL_IM_MODULE/GLFW_IM_MODULE）
#    与 NIXOS_OZONE_WL 不在此重复：单一来源 = 系统层 modules/locale.nix
#    （会话作用域）+ home/modules/desktop/niri.nix 的 settings.environment（合成器作用域），
#    双作用域为 fcitx/niri 官方推荐（见 STANDARDS §4）
# ============================================================
_:

{
  home.sessionVariables = {
    # ---------- Wayland ----------
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    QT_QPA_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "Niri";

    # ---------- 用户专属（不依赖 IM 体系）----------
    PASSWORD_STORE = "gnome-listsecret";

    # --- man 手册分页（bat 渲染，MANROFFOPT 保留粗体/下划线）---
    MANPAGER = "bat --paging=never";
    MANROFFOPT = "-c";
  };
}
