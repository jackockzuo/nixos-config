# ============================================================
# secrets.nix —— sops-nix 秘密管理（STANDARDS.md §5）
# 职责：声明 sops 秘密、解密 key、消费方接线
# 修改：加新秘密 → 改 secrets/secrets.yaml + 这里加 sops.secrets.<name>
# 关联：.sops.yaml（加密规则与 age 公钥）、secrets/secrets.yaml（加密内容）
# ============================================================
{ config, ... }:

{
  sops = {
    # 默认加密文件：secrets/secrets.yaml（提交 git，仅密文）
    defaultSopsFile = ../secrets/secrets.yaml;

    # 🔴 主机解密 key：指向本机 age 私钥（与 .sops.yaml 的 age19j8... 公钥配对）
    # 私钥永不进仓库/进 git；root 运行 sops-install-secrets 可读（权限 600 不挡 root）
    age.keyFile = "/home/ran/.config/sops/age/keys.txt";

    # ---- 秘密声明 ----
    # 🔴 neededForUsers = true：解密到 /run/secrets-for-users，必须在 users 创建
    #    【之前】解密（否则 users 模块读不到 hashedPasswordFile）
    #    ⚠️ neededForUsers 秘密不能设 owner（users 尚不存在）
    secrets = {
      github-token = { }; # → /run/secrets/github-token
      user-password.neededForUsers = true;
      root-password.neededForUsers = true;
    };

    # ---- 消费方：nix-daemon 的 GitHub access-tokens ----
    # 🔴 原理：sops 秘密在【激活期】解密，而 nix.settings.access-tokens 是【构建期】值，
    #    无法直接注入。改用 NIX_CONFIG 环境变量：sops 模板在激活期生成 env 文件，
    #    nix-daemon 启动时读取（NIX_CONFIG 优先级高于 /etc/nix/nix.conf）。
    templates."nix-daemon.env" = {
      content = ''
        NIX_CONFIG=access-tokens = github=${config.sops.placeholder.github-token}
      '';
      # token 更新时自动重启 nix-daemon（否则旧配置常驻）
      restartUnits = [ "nix-daemon.service" ];
    };
  };
  systemd.services.nix-daemon.serviceConfig.EnvironmentFile = [
    config.sops.templates."nix-daemon.env".path
  ];
}
