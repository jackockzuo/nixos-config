# ============================================================
# nix.nix —— Nix 客户端/daemon
# 职责：镜像源、GC、experimental-features、direnv/nix-ld/nix-index
# 修改：换源/调 GC 策略 → 改这里
# 关联：modules/secrets.nix（sops 模板注入 github-token 到 NIX_CONFIG）
# ============================================================
{ config, pkgs, ... }:

{
  # ============ Nix：国内镜像 + daemon 调优 + 自动 GC ============
  nix = {
    settings = {
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
      # 🔴 防止 GC 误伤（2026-08-29 事故）：--no-link 构建的 toplevel 无 gc root，
      #    自动 GC 清掉后 switch 需重新下载（曾撞 nyx 缓存网络故障）。
      #    keep-outputs 保留构建产物；min-free/max-free 磁盘将满自动提前清理
      keep-outputs = true;
      min-free = "2G"; # 剩余 <2G 时自动触发 GC
      max-free = "8G"; # GC 清理到剩 8G 为止
      # 🔴 GitHub token 不在本文件：由 modules/secrets.nix 的 sops 模板
      #    （NIX_CONFIG env file）注入 nix-daemon 的 access-tokens
    };
    # 系统级自动 GC（保留 7 天）
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  # 🔴 nix-daemon 下载走代理（TUN 模式未生效/绕过时兜底）
  # 否则 daemon（root 服务）不继承终端 export，直连 cache.nixos.org 龟速
  # 地址单一来源：modules/proxy.nix 的 options.proxy
  systemd.services.nix-daemon.environment = {
    http_proxy = config.proxy.address;
    https_proxy = config.proxy.address;
    all_proxy = config.proxy.address;
    # 🔴 Go 模块国内代理（2026-08-30 修复）：nixpkgs buildGoModule 的 go-modules 派生
    #    impureEnvVars 含 GOPROXY（继承 daemon 环境）→ 这里设置后 Go 构建走 goproxy.cn，
    #    不再直连 proxy.golang.org（国内 TLS 超时 → sops-install-secrets/DMS 现场编译必失败）
    GOPROXY = "https://goproxy.cn,direct";
  };

  # 🔴 nix 客户端构建也走 Go 国内代理（nix develop / nix shell 内 buildGoModule 场景）
  nix.settings.extra-sandbox-paths = [ ];
  # 客户端侧 GOPROXY：供 nix 单机/本地构建继承（daemon 构建由上方环境变量覆盖）
  environment.sessionVariables.GOPROXY = "https://goproxy.cn,direct";

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

  # ============ 客户端工具（曾独立文件并入）：direnv / nix-ld / nix-index ============
  programs = {
    # direnv：目录环境
    # 允许 unfree：单一来源在 modules/system.nix（此处不再重复声明）
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # nix-ld：运行第三方二进制
    nix-ld = {
      enable = true;
      # 这一套组合拳基本覆盖了 99% 的二进制程序需求
      libraries = with pkgs; [
        # 基础系统库
        stdenv.cc.cc
        openssl
        zlib
        fuse3
        icu
        libuuid
        xz
        gettext
        libxml2

        # 图形界面与 UI 库 (GTK/Qt/Electron 所需)
        glib
        nss
        nspr
        atk
        at-spi2-atk
        at-spi2-core
        dbus
        dconf
        expat
        fontconfig
        freetype
        gdk-pixbuf
        gtk3
        pango
        cairo
        libdrm
        mesa # 用于 OpenGL/Vulkan

        # X11 相关库
        libx11
        libice # Avalonia X11 后端 ICE 会话管理（omercore-gui 依赖 libICE.so.6）
        libsm # X11 会话管理（omercore-gui 依赖 libSM.so.6）
        libxcursor
        libxdamage
        libxext
        libxfixes
        libxi
        libxrandr
        libxrender
        libxtst
        libxcb
        libxcomposite
        libxscrnsaver
        libxinerama

        # Wayland 相关
        wayland
        libxkbcommon

        # 音频视频处理
        alsa-lib
        libpulseaudio
        libvorbis
        libogg
        libopus
        libvpx
        ffmpeg

        # 网络与下载
        curl
        libidn2
        libssh2
        nghttp2
        rtmpdump

        # 常用开发语言运行时支持
        python3
        systemd # 很多 binary 会链接 libsystemd.so
      ];
    };

    # nix-index：command-not-found 补全（曾独立 nix-addons/nix-index.nix，并入）
    nix-index.enable = true;
    # 禁用系统默认 command-not-found（更新慢、经常找不到包）
    command-not-found.enable = false;
  };
}
