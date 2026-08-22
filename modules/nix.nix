# ============================================================
# nix.nix —— Nix 客户端/daemon
# 职责：镜像源、GC、experimental-features
# 修改：换源/调 GC 策略 → 改这里
# 关联：modules/secrets.nix（sops 模板注入 github-token 到 NIX_CONFIG）
# ============================================================
{ config, ... }:

{
  # ============ Nix：国内镜像 + daemon 调优 ============
  nix.settings = {
    # 🔴 nyx 缓存放首位：优先获取 CachyOS 预编译内核/nvidia 模块（本地无则避免现场编译）。
    #    ⚠️ 官方现行缓存是 nyx-cache.chaotic.cx（旧 nyx.cachix.org 已迁移，key 不同！）
    #    若 chaotic 再次迁移缓存地址：要么改这里，要么删掉本节改回自动（cache.enable=true）
    substituters = [
      "https://nyx-cache.chaotic.cx/"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    # 🔴 GitHub token 不在本文件：由 modules/secrets.nix 的 sops 模板
    #    （NIX_CONFIG env file）注入 nix-daemon 的 access-tokens
  };
  # 🔴 nix-daemon 下载走代理（TUN 模式未生效/绕过时兜底）
  # 否则 daemon（root 服务）不继承终端 export，直连 cache.nixos.org 龟速
  # 地址单一来源：modules/proxy.nix 的 options.proxy
  systemd.services.nix-daemon.environment = {
    http_proxy = config.proxy.address;
    https_proxy = config.proxy.address;
    all_proxy = config.proxy.address;
  };
  # 系统级自动 GC（保留 7 天）
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  # 允许 unfree：单一来源在 modules/system.nix（此处不再重复声明）
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # ============ Chaotic-Nyx（CachyOS 高性能包生态）============
  chaotic.nyx = {
    # CachyOS 包 overlay：提供 linuxPackages_cachyos 等高性能包（boot.nix 内核切换依赖它）
    overlay.enable = true;
    # ❌ cache.enable 默认 true 会自动追加 nyx 缓存配置到 nix.settings（顺序不可控），
    #    与上方手动配置（nyx 首位 + 国内镜像）冲突/重复 → 显式关闭，缓存由本文件全权管理。
    cache.enable = false;
    # ❌ cpu-set 选项在本版本 chaotic 中不存在（仅 cache/nixPath/overlay/registry）；
    #    CPU governor 改由 services.tlp.settings 配置（见 services.nix，AC=performance）。
  };
}
