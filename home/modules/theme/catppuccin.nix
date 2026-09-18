# ============================================================
# theme.nix —— 用户级配色（catppuccin/nix，Home Manager 作用域）
# 职责：全局开关 + flavor/accent（my 单一来源，与系统层 modules/theme.nix 同源）
#       + 仅列出与 autoEnable 默认相悖的端口开关
# autoEnable：已启用程序的配色端口自动跟随（不再逐个手写 enable）
# ============================================================
{ my, ... }:

{
  catppuccin = {
    enable = true;
    autoEnable = true;
    inherit (my.catppuccin) flavor accent;

    # 光标端口上游默认不随 autoEnable（useGlobalEnable=false），显式打开
    cursors.enable = true;

    # GTK 图标保留仓库自定义 Papirus + Tela-circle 回退链（appearance.nix），
    # 不用 catppuccin-papirus-folders（无 Tela 兜底，会丢图标回退）
    gtk.icon.enable = false;

    # Neovim 配色由 Nixvim 的 colorschemes.catppuccin 管理（tools/nixvim.nix），
    # 关闭 catppuccin.nvim 避免双重配置
    nvim.enable = false;

    # Firefox 为包安装（非 programs.firefox），无 profile 可注入，显式关闭
    firefox.enable = false;

    # Qt 走 gtk3 平台主题（appearance.nix），非 Kvantum，关闭其断言与主题注入
    kvantum.enable = false;

    # Hyprlock 只取配色变量（$mauve/$base/$text...），锁屏布局由 hyprlock.nix 自定义
    hyprlock = {
      enable = true;
      useDefaultConfig = false;
    };
  };
}
