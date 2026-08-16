# ============================================================
# pass.nix —— pass（Unix 密码管理，gpg 加密）+ gpg 配置
# ============================================================
# 说明：
#   - pass 是 Unix 密码管理器：密码以文件形式存放于 ~/.password-store，
#     内容由 gpg 非对称加密（密钥即 "密码库主密钥"）。
#   - 首次使用（手动，需先有 gpg 密钥对）：
#       gpg --full-generate-key          # 生成密钥对（或用本文件 gpg.conf 的默认算法）
#       pass init <gpg-id>               # 用密钥 ID 初始化密码库
#       pass insert website/example      # 交互式存入密码
#       pass generate website/example 20 # 生成 20 位随机密码
#   - 日常用法：pass show <name> / pass edit <name> / pass rm <name>。
#   - 依赖：pass 本身、pinentry（用于弹窗输入 gpg 主密码），由 orchestrator 统一加入 home.packages。
#   - 注意：gpg 配置目录固定为 ~/.gnupg（GNUPGHOME 默认值），
#     因此必须用 home.file.".gnupg/..."（映射到 ~/.gnupg/），
#     不能用 xdg.configFile（它只会映射到 ~/.config/，gpg 不会读取）。
_:

{
  # ------------------------------------------------------------
  # gpg 配置 —— pass 的加密后端
  # gpg 不会自动生成 gpg.conf（无被覆盖风险），故不需要 force
  # ------------------------------------------------------------
  home.file.".gnupg/gpg.conf".text = ''
    # 密钥算法优先现代曲线（Ed25519 签名 + Curve25519 加密）
    default-new-key-algo ed25519+cv25519
    # 内存中缓存对称密钥主密码
    no-symkey-cache
    # 信任模型：TOFU（首次见信任）+ PGP 信任回退。
    # 避免每次签名/加密询问信任级别；tofu+pgp 为 GnuPG 2.2+ 合法组合，
    # 若觉得 TOFU 数据库多余可改为 classic 或直接删除本行
    trust-model tofu+pgp
    # 显示指纹
    with-fingerprint
  '';

  # ------------------------------------------------------------
  # gpg-agent 配置 —— 主密码缓存时长
  # 同样不会被 gpg-agent 自动生成，home.file 直接写入 ~/.gnupg/
  # ------------------------------------------------------------
  home.file.".gnupg/gpg-agent.conf".text = ''
    # 主密码在内存中的缓存时长（秒）
    # 默认 600s 太短，日常频繁用到 gpg 时每次重输很烦
    default-cache-ttl 1800
    # 最长缓存时长：即使持续使用，也最多缓存 2 小时
    max-cache-ttl 7200
  '';

  # 说明：pass 首次使用需要 pinentry 程序（弹窗/终端输入 gpg 主密码）。
  # pinentry 与 pass 的安装由 orchestrator 在 home.packages 统一处理，本文件不添加包。
  # 若 rebuild 后 pass init 报 "gpg: no pinentry"，
  # 请确认 home.packages 中已含 pinentry（如 pinentry-curses 或 pinentry-gnome3）。
}
