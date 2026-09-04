# users.nix —— 用户与权限
# 职责：用户/root、groups、登录 shell、密码（sops 管理）
# 用户名单一来源：flake.nix 顶部 my.username（users.${my.username} 自动跟随）
# ============================================================
{
  config,
  pkgs,
  my,
  ...
}:

{
  users = {
    users.${my.username} = {
      isNormalUser = true;
      # 登录 shell 改为 fish：打开终端即进 fish；bash 依然可用（fish 里直接敲 bash 切换）
      shell = pkgs.fish;
      extraGroups = [
        "wheel"
        "networkmanager"
        "podman"
        "input"
      ];
      # 密码哈希由 sops 管理（STANDARDS §6）：neededForUsers 秘密在 users
      #    创建前解密到 /run/secrets-for-users，经 hashedPasswordFile 读取。
      #    事故根因已修复（age.keyFile 移到 / 下），sops 链恢复 (REF:2026-08-17-niri-login)
      hashedPasswordFile = config.sops.secrets.user-password.path;
    };
    users.root.hashedPasswordFile = config.sops.secrets.root-password.path;
    mutableUsers = false;
  };
  # 系统层启用 fish 集成：users.users.<user>.shell = pkgs.fish 要求系统层
  # programs.fish.enable = true（生成 /etc/fish 配置和 PATH），否则 rebuild 断言失败。
  programs.fish.enable = true;
}
