# ============================================================
# env.nix —— 用户级环境变量（sessionVariables）
# 职责：Wayland/输入法/代理等全局环境变量的唯一落点
# 修改：加环境变量 → 改这里（变量按用途分节，不混堆）
# 关联：proxy.nix（代理变量按"代理关注点"放 network/ 更合理，
#       但如想在单一文件收拢全部 sessionVariables 也可移入）
# ============================================================
_:

{
  # ---------- Wayland ----------
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    QT_QPA_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "Niri";

    # --- 输入法（与系统层 locale.nix 的 environment.sessionVariables 配合）---
    # --- 现代写法（fcitx wiki 2025-09 + niri#3099 验证配置）---
    # 不设全局 GTK_IM_MODULE：Wayland 原生 GTK3/4 自动走 text-input-v3，
    # 全局设置反而触发候选框闪烁；X11/XWayland 应用由
    # home/modules/desktop/fcitx5.nix 的 gtk-{2,3,4} 配置里 gtk-im-module 接管。
    QT_IM_MODULE = "fcitx"; # Qt4/5 及非 KWin 合成器需要
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    # 🔴 kitty 源码（glfw/ibus_glfw.c）只认 GLFW_IM_MODULE=ibus，
    # 其他值直接忽略；fcitx5 提供 ibus 协议兼容，ibus 值对 fcitx5 有效。
    GLFW_IM_MODULE = "ibus";

    # --- 不依赖 ---
    PASSWORD_STORE = "gnome-listsecret";

    # --- man 手册分页（bat 渲染，MANROFFOPT 保留粗体/下划线）---
    MANPAGER = "bat --paging=never";
    MANROFFOPT = "-c";
  };
}
