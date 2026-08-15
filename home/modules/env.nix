# ============================================================
# env.nix —— 用户级环境变量（sessionVariables）
# 职责：Wayland/输入法/代理等全局环境变量的唯一落点
# 修改：加环境变量 → 改这里（变量按用途分节，不混堆）
# 关联：proxy.nix（代理变量按"代理关注点"放 network/ 更合理，
#       但如想在单一文件收拢全部 sessionVariables 也可移入）
# ============================================================
{ ... }:

{
  # ---------- Wayland ----------
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    QT_QPA_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "Niri";

    # --- 输入法（与系统层 locale.nix 的 environment.sessionVariables 配合）---
    # --- 修复 Fcitx5 Wayland 卡顿与光标跟随 ---
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus"; # fcitx5 提供 ibus 兼容，GLFW 应用走 ibus 通道

    # --- 不依赖 ---
    PASSWORD_STORE = "gnome-listsecret";
  };
}
