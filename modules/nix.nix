# ============================================================
# nix.nix —— Nix 客户端/daemon
# 职责：镜像源、GC、experimental-features、nix-ld/nix-index
# ============================================================
{ my, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nix-update # 更新 nixpkgs
    nix-du
    nix-tree
    nixdoc
    nix-init
    nix-output-monitor
    flake-checker
    nix-melt
    nix-health
    nixd
    nixfmt
    nh
    nvd
    deadnix
    devenv # 开发环境管理
    cachix # 缓存管理工具
    angrr
    optnix
    # 文档检索 / 装机
    manix # CLI 搜 NixOS/HM 选项与文档
    nix-search-tv # TUI 实时搜 nixpkgs / options
    nixos-anywhere
    fh
  ];

  nix = {
    settings = {
      # 二进制缓存：国内镜像（SJTU/NJU）+ 社区 cachix + CUDA
      # cache.nixos.org（本体）与其公钥由 nixpkgs 默认自动追加兜底，故不手写；
      # TUNA/USTC 实测慢已移除。
      substituters = [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://mirror.nju.edu.cn/nix-channels/store"

        "https://devenv.cachix.org"
        "https://numtide.cachix.org"
        "https://nix-community.cachix.org" # 社区工具加速
        "https://mic92.cachix.org" # Mic92 项目（sops-nix 等）
        "https://git-hooks.cachix.org" # git-hooks.nix
        "https://pre-commit-hooks.cachix.org" # pre-commit-hooks
        "https://nix-gaming.cachix.org" # nix-gaming（wine/proton/dxvk）

        "https://cache.nixos-cuda.org" # CUDA/NVIDIA 驱动加速
      ];
      # cache.nixos.org 的公钥由 nixpkgs 默认提供，无需手写
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "mic92.cachix.org-1:gi8IhgiT3CYZnJsaW7fxznzTkMUOn1RY4GmXdT/nXYQ="
        "git-hooks.cachix.org-1:t3VIYDdXlezkNY1/sRtYKzxMVKTgn+uAR9VWCXHRPeI="
        "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];

      trusted-users = [
        "@wheel"
        my.username
      ];
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
        "auto-allocate-uids"
        "cgroups"
      ];
      auto-optimise-store = true;
      # GC 误伤防护：keep-outputs 保留构建产物；min-free/max-free 磁盘将满自动提前清理
      keep-outputs = true;
      min-free = "2G";
      max-free = "8G";
      # GitHub token 由 modules/secrets.nix 的 sops 模板注入（NIX_CONFIG env file）

      # 下载/构建参数
      http2 = false; # 避免国内代理/镜像源误杀
      connect-timeout = 5;
      stalled-download-timeout = 90;
      http-connections = 24; # 降并发，避免小管道拥塞
      max-substitution-jobs = 24;
      warn-dirty = false;
      max-jobs = "auto"; # 自动根据 CPU 核心数调度编译
      cores = 0; # 允许单任务用满全部核心
      builders-use-substitutes = true;
      log-lines = 50; # 编译失败时打印更多日志便于排查
    };

    # GitHub token 片段（sops 渲染，见 modules/secrets.nix）：客户端解析 flake input
    #   的 HEAD 时经 access-tokens 认证，避免匿名 60 次/小时限流（nr -u 卡住）。
    extraOptions = ''
      include ${my.nixAccessTokensPath}
    '';
    # include 目标是运行时才存在的 sops 文件，构建期 `nix config show` 会报
    #   "file not found"。放宽为只查未知设置项（unknown setting），其余解析错误不 fail；
    #   include 缺失在运行时有 systemd-tmpfiles 兜底（见 modules/secrets.nix）。
    checkAllErrors = false;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    # 硬链接去重（STANDARDS §5）：auto-optimise-store 入库时去重，
    #   optimise.automatic 周期全库去重（已有文件也去重，防 store 膨胀）
    optimise.automatic = true;
    # nixpkgs registry 改由 flake.nix 设置（nix.registry.nixpkgs.flake = inputs.nixpkgs）：
    #   指向 flake.lock 锁定的本地 store 路径，`nixpkgs#...` 纯本地解析、不再联网。
    #   实测（2026-09-17）TUNA git 镜像 ls-remote 47~64s、浅克隆排队 3min+ 不返回；
    #   而 TUNA 的 nix-channels tarball 镜像可达 22.7 MB/s（git 镜像不可用于加速）。
  };

  # nix-daemon 环境（2026-09-03：http(s)_proxy 随 fcclient/dae 清理移除）
  # Go 模块国内代理：sops-install-secrets/DMS 现场编译需要
  systemd.services.nix-daemon.environment = {
    GOPROXY = "https://goproxy.cn,direct";
  };

  # 客户端侧 GOPROXY（nix develop / nix shell 内 buildGoModule 场景）
  environment.sessionVariables.GOPROXY = "https://goproxy.cn,direct";

  # 客户端工具：nix-ld / nix-index
  programs = {
    nh = {
      enable = true;
      flake = "../";

    };

    nix-ld = {
      enable = true;
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
        mesa

        # X11 相关库
        libx11
        libice # X11 session 管理（老 GUI/nix-ld 程序）
        libsm # X11 session 管理（老 GUI/nix-ld 程序）
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

        # 开发语言运行时
        python3
        systemd
      ];
    };
    nix-index.enable = true;
    command-not-found.enable = false;
  };
}
