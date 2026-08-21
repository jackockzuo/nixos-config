# ============================================================
# office.nix —— 办公效率
# 已启用：WPS Office（wpsoffice-cn）/ Zotero（文献管理）/ Obsidian（笔记）
# 使用方式：home.packages = with pkgs; [ obsidian ... ];
# ============================================================
{ pkgs, ... }:

{
  # 办公套件与笔记工具（已启用）
  home.packages = with pkgs; [
    wpsoffice-cn
    zotero
    obsidian
  ];
}
