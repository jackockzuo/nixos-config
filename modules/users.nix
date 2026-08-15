# ============================================================
# users.nix —— 用户与权限
# 职责：用户 ran/root、groups、登录 shell、初始密码
# 修改：加用户/改权限组/改 shell → 改这里
# 关联：shell.nix（fish 由用户级 home-manager 管理别名/主题）
# ============================================================
{ pkgs, ... }:

{
  # ============ 用户 ============
  users.users.ran = {
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
    # 临时初始密码：登录后立即 `passwd` 修改，然后删掉这行再 rebuild
    initialPassword = "ran";
  };
  users.users.root.initialPassword = "rootpassword";
  users.mutableUsers = false;
  # 🔴 系统层启用 fish 集成：users.users.ran.shell = pkgs.fish 要求系统层
  # programs.fish.enable = true（生成 /etc/fish 配置和 PATH），否则 rebuild 断言失败。
  # 用户级配置（别名/主题/函数）由 home-manager 的 programs.fish 负责。
  programs.fish.enable = true;
}
