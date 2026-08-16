# ============================================================
# topgrade.nix —— topgrade 一键升级（含 NixOS flake 兼容处理）
# ============================================================
{ pkgs, ... }:

{
  # topgrade 一键升级（用 programs.topgrade 管理配置，见下）
  # 🔴 topgrade 对 NixOS 默认跑传统模式 `nixos-rebuild switch --upgrade`，
  #    会去 /etc/nixos/ 找 configuration.nix——但本仓库是 flake 架构（/etc/nixos 为空）→ 报错。
  #    解决方案：disable 内置 system 步骤 + 自定义命令跑 flake rebuild。
  programs.topgrade = {
    enable = true;
    settings = {
      misc = {
        # 禁用内置 NixOS 系统更新（传统模式，找不到 flake 配置）
        disable = [ "system" ];
        # 开头就缓存 sudo 凭证，避免中途卡密码
        pre_sudo = true;
        set_title = false;
      };
      commands = {
        "NixOS flake rebuild" = "sudo nixos-rebuild switch --flake /home/ran/nixos-config#omen";
      };
    };
  };
  # 🔴 force 覆盖已存在的 ~/.config/topgrade.toml：
  # topgrade 首次运行时自动生成的默认模板（全注释）与 HM 声明式配置冲突，
  # 不设 force 会导致 home-manager activation 整体失败（checkLinkTargets 报
  # "would be clobbered"），连带 fastfetch 等其他新配置全部无法部署。
  xdg.configFile."topgrade.toml".force = true;
}
