# ============================================================
# users.nix —— 用户与权限
# 职责：用户/root、groups、登录 shell、密码（sops 管理）
# 修改：加用户/改权限组/改 shell → 改这里
# 🔴 用户名单一来源：flake.nix 顶部 my.username（users.${my.username} 自动跟随）
# 关联：home/modules/tools/fish.nix（fish 由用户级 home-manager 管理别名/主题）
# ============================================================
{
  config,
  pkgs,
  my,
  ...
}:

{
  users = {
    # ============ 用户 ============
    users.${my.username} = {
      isNormalUser = true;
      # 🔴 登录 shell 改为 fish：打开终端（kitty 用登录 shell）即进 fish；
      # bash 依然可用（系统自带，fish 里直接敲 `bash` 切换，脚本 #!/bin/bash 不受影响）
      shell = pkgs.fish; # input: DMS evdev 手势需要；podman: distrobox 容器
      extraGroups = [
        "wheel"
        "networkmanager"
        "podman"
        "input"
      ];
      # 🔴 密码哈希由 sops 管理（STANDARDS §6）：neededForUsers 秘密在 users
      #    创建前解密到 /run/secrets-for-users，经 hashedPasswordFile 读取。
      #    ✅ 不再有明文密码（旧 initialPassword 已删除）。
      #    改密码：mkpasswd -s 生成新哈希 → 更新 secrets/secrets.yaml 的 user-password
      #    ⚠️ 2026-08-17 事故根因已修复（age.keyFile 移到 / 下），sops 链恢复；
      #    此前锁死即因 keyFile 在 /home（开机激活时未挂载）→ sops 解密失败。
      hashedPasswordFile = config.sops.secrets.user-password.path;
    };
    users.root.hashedPasswordFile = config.sops.secrets.root-password.path;
    mutableUsers = false;
  };
  # 🔴 系统层启用 fish 集成：users.users.<user>.shell = pkgs.fish 要求系统层
  # programs.fish.enable = true（生成 /etc/fish 配置和 PATH），否则 rebuild 断言失败。
  # 用户级配置（别名/主题/函数）由 home-manager 的 programs.fish 负责。
  programs.fish.enable = true;
}
