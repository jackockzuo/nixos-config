# ============================================================
# secrets.nix —— sops-nix 秘密管理（STANDARDS §6）
# 职责：声明 sops 秘密、解密 key、消费方接线
# ============================================================
{ config, my, ... }:

{
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;

    # 私钥必须放 / 下（开机早期可达），不能放 /home（子卷未挂载）(REF:2026-08-17-niri-login)
    age.keyFile = "/var/lib/sops-nix/keys.txt";

    # 秘密声明：neededForUsers 秘密必须在 users 创建前解密
    secrets = {
      github-token = { };
      user-password.neededForUsers = true;
      root-password.neededForUsers = true;
    };

    # GitHub token → nix 的 access-tokens 配置片段（被 /etc/nix/nix.conf include）。
    # 根因：flake input 的 HEAD 解析发生在客户端 nix 进程（非 nix-daemon），
    #   匿名 api.github.com 仅 60 次/小时，经代理共享出口很容易打满 → nr -u 卡住/403。
    # Nix 式做法：sops 激活期渲染到运行时路径，再由 nix.conf `include` 消费；
    #   token 永不进 /nix/store，也不写进 world-readable 的 /etc/nix/nix.conf 本体。
    templates."nix-access-tokens" = {
      path = my.nixAccessTokensPath;
      content = "access-tokens = github=${config.sops.placeholder.github-token}";
      owner = my.username;
      mode = "0400";
    };
  };

  # 兜底：预置空文件，保证 include 目标永不悬空。
  #   sops 成功 → 原子替换为指向真实片段的软链；
  #   sops 失败 → 保持空文件，nix 退化为匿名（慢但可用），不会 brick。
  #   systemd-tmpfiles 的 f 只在“文件不存在”时创建，不覆盖 sops 生成的软链，
  #   故与 sops 的先后顺序无关。
  systemd.tmpfiles.rules = [
    "f ${my.nixAccessTokensPath} 0400 ${my.username} users -"
  ];
}
