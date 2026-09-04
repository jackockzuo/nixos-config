# ============================================================
# secrets.nix —— sops-nix 秘密管理（STANDARDS §6）
# 职责：声明 sops 秘密、解密 key、消费方接线
# ============================================================
{ config, ... }:

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

    # nix-daemon GitHub token：sops 激活期解密 → NIX_CONFIG env file → daemon 启动时读取
    templates."nix-daemon.env" = {
      content = ''
        NIX_CONFIG=access-tokens = github=${config.sops.placeholder.github-token}
      '';
      restartUnits = [ "nix-daemon.service" ];
    };
  };
  systemd.services.nix-daemon.serviceConfig.EnvironmentFile = [
    config.sops.templates."nix-daemon.env".path
  ];
}
