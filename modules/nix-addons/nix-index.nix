# ============================================================
# nix-index.nix —— 命令补全数据库
# 职责：nix-index（~/.nix-index 数据库）+ 关闭慢速默认 command-not-found
# 修改：不需要时 → 整段注释；注意同时从 modules/default.nix imports 删掉本行
# ============================================================
_: {
  # 1. 开启 nix-index 模块
  programs.nix-index.enable = true;

  # 2. 禁用系统默认的 command-not-found（更新慢、经常找不到包）
  programs.command-not-found.enable = false;
}
