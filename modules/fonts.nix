# ============================================================
# fonts.nix —— 系统字体
# 职责：安装全局字体（终端/输入法/中文回退）
# 修改：加/换字体 → 改这里
# 关联：home-manager/desktop/appearance.nix（fontconfig 渲染规则）
# ============================================================
{ pkgs, ... }:

{
  # ============ 字体（终端 Maple Mono + UI 默认中文字体）============
  fonts.packages = with pkgs; [
    maple-mono.NF-CN # "Maple Mono NF CN"（仅终端 kitty 使用）
    nerd-fonts.jetbrains-mono # 浏览器/等宽代码块（fontconfig monospace 首选）
    noto-fonts-cjk-sans # 中文默认（浏览器/UI/输入法候选框）
    noto-fonts
    inter # DMS UI 字体（Inter Variable，桌面壳运行时使用）
    fira-code # DMS 等宽字体（Fira Code，桌面壳 mono 使用）
  ];
}
