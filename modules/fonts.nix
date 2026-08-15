# ============================================================
# fonts.nix —— 系统字体
# 职责：安装全局字体（终端/输入法/中文回退）
# 修改：加/换字体 → 改这里
# 关联：home-manager/desktop/appearance.nix（fontconfig 渲染规则）
# ============================================================
{ pkgs, ... }:

{
  # ============ 字体（kitty/fcitx5 的 Maple Mono NF CN + 中文字体）============
  fonts.packages = with pkgs; [
    maple-mono.NF-CN # "Maple Mono NF CN"（kitty + fcitx5 classicui 指定）
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans # 中文回退
    noto-fonts
  ];
}
