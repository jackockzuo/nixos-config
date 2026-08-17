# ============================================================
# users.nix —— 用户与权限
# 职责：用户 ran/root、groups、登录 shell、密码（sops 管理）
# 修改：加用户/改权限组/改 shell → 改这里
# 关联：tools/terminal/fish.nix（fish 由用户级 home-manager 管理别名/主题）
# ============================================================
{ config, pkgs, ... }:

{
  users = {
    # ============ 用户 ============
    users = {
      ran = {
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
        # 🔴 2026-08-17 故障恢复：直写密码哈希（临时替代 sops hashedPasswordFile）。
        #    实测 sops→/run/secrets-for-users 链失效：su 用 "ran" 验证被拒，而沙箱
        #    复现 update-users-groups.pl 证明脚本逻辑正确 → 断点在 sops 解密写文件环节。
        #    直接把已验证的哈希（mkpasswd yescrypt，明文 = 密码 "ran"）写进配置，
        #    构建期即入 users-groups.json，激活时不经文件读取，必然生效。
        #    ⚠️ mutableUsers=false：密码只能在配置里改，passwd 运行时改会被 rebuild 覆盖。
        #    恢复 sops 方案：定位 sops-install-secrets 写文件内容问题后，改回
        #    hashedPasswordFile = config.sops.secrets.user-password.path（见 STANDARDS §5）。
        hashedPassword = "$y$j9T$HYOsuolSk8zMUrJBaeiDP0$7qQkf3M0GpwAWT.qUIeGMO.1rhPlGWby3i/bM9PwT29";
      };
      root.hashedPasswordFile = config.sops.secrets.root-password.path;
    };
    mutableUsers = false;
  };
  # 🔴 系统层启用 fish 集成：users.users.ran.shell = pkgs.fish 要求系统层
  # programs.fish.enable = true（生成 /etc/fish 配置和 PATH），否则 rebuild 断言失败。
  # 用户级配置（别名/主题/函数）由 home-manager 的 programs.fish 负责。
  programs.fish.enable = true;
}
