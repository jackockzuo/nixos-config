{
  lib,
  ...
}:

{
  # ============================================================
  # DMS (DankMaterialShell) 配置管理
  #
  # 策略（DMS 运行时会写回配置，不能只读 symlink）：
  # - themes/（静态主题）→ symlink 管理，DMS 只读
  # - settings.json / monitors.json（运行时状态）→ activation 首次部署仅当目标不存在时
  # - 登录界面（DMS greeter）主题由 `dms greeter sync` 同步，无需单独配置
  # ============================================================

  # 静态主题目录（DMS 只读，可 symlink）
  xdg.configFile."DankMaterialShell/themes" = {
    source = ../../source/dms/themes;
    recursive = true;
    force = true; # 覆盖已存在的真实目录（内容与快照一致）
  };

  # 动态配置：仅在配置缺失时部署（重装恢复），不干扰运行中的 DMS
  # 注意：themes 已被上方 xdg.configFile 以 symlink 管理（与 source 是同一 store 文件），
  # 用 cp -rn 跳过已存在项 + || true 兜底。
  home.activation.restoreDmsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/DankMaterialShell"
    if [ ! -e "$HOME/.config/DankMaterialShell/settings.json" ]; then
      $DRY_RUN_CMD cp -rn "${../../source/dms}/." "$HOME/.config/DankMaterialShell/" || true
    fi
    $DRY_RUN_CMD chmod -R u+w "$HOME/.config/DankMaterialShell"
  '';
}
