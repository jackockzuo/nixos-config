# ============================================================
# theme.nix —— 系统级配色（catppuccin/nix，NixOS 作用域）
# 职责：全局开关 + flavor/accent（my 单一来源）+ 仅系统端口（fcitx5/limine）
# 用户级配色端口（GTK/终端/提示符/图标等）见 home/modules/theme/
# ============================================================
{ my, ... }:

{
  catppuccin = {
    enable = true;
    autoEnable = true; # 显式声明，避免上游 autoEnable 迁移警告（STANDARDS §8）
    inherit (my.catppuccin) flavor accent;

    # Catppuccin 二进制缓存（catppuccin.cachix.org）：主题包免本地构建
    cache.enable = true;

    # fcitx5：安装主题 addon；/etc/xdg 的主题名会被用户配置遮蔽，
    # 故用户层 classicui.conf 显式给出同名主题（见 home/modules/desktop/fcitx5.nix）
    fcitx5.enable = true;

    # 🔴 不接管 Limine：主机 boot.nix 的“随机蓝色壁纸 + 自定义界面配色”优先。
    #    catppuccin.limine 的 extraConfig 生成在 limine.conf 最前，会被后续
    #    style.*（term_palette/interface_*）完全覆盖 = 无效果，故显式关闭。
    limine.enable = false;
  };
}
