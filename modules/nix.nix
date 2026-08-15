# ============================================================
# nix.nix —— Nix 客户端/daemon
# 职责：镜像源、GC、experimental-features
# 修改：换源/调 GC 策略 → 改这里
# 关联：flake.nix（secrets 输入注入 github-token 到 access-tokens）
# ============================================================
{ ... }:

{
  # ============ Nix：国内镜像 + daemon 调优 ============
  nix.settings = {
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    # 🔴 GitHub token 不在本文件：由 flake.nix 的 secrets path 输入注入 access-tokens
  };
  # 系统级自动 GC（保留 14 天）
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
