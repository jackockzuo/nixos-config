# ============================================================
# social.nix —— 社交/即时通讯
# 职责：微信 / Telegram / Discord / Slack / QQ 等
# 修改：加社交软件 → 改 home.packages；改应用配置 → 下方加 xdg.configFile
# 注意：QQ 的 Wayland 标志原在 qq.nix，已并入本文件
# ============================================================
{ pkgs, ... }:

{
  # ---- QQ 原生 Wayland（迁移自原 qq.nix）----
  # 效果：QQ 以原生 Wayland 模式运行（替代 XWayland 转译）
  xdg.configFile."qq-flags.conf" = {
    force = true; # 覆盖原作者旧配置
    text = ''
      --ozone-platform=wayland
    '';
  };

  # ---- 预留：其他社交软件 ----
  home.packages = with pkgs; [
    qq
    wechat
  ];
}
