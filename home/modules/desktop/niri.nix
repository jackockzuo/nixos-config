{ ... }:

{
  # ============================================================
  # 桌面环境配置管理模块（niri 生态）
  # 原则：桌面组件（niri/hyprlock 等）由 NixOS 系统层安装，
  #       HM 只管理配置文件（~/.config/ 下所有映射）
  # ============================================================

  # 2. 映射 niri 整个目录（包括 binds.kdl、layout.kdl、scripts 文件夹等）
  xdg.configFile."niri" = {
    source = ../../source/niri;
    recursive = true;
    # 覆盖旧的独立 blur.kdl 真文件（现已并入 source/niri 由 home-manager 管理）
    force = true;
  };
}
