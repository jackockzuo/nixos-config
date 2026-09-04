# ============================================================
# nix.nix —— Nix 客户端/daemon
# 职责：镜像源、GC、experimental-features、nix-ld/nix-index
# ============================================================
{ config, pkgs, ... }:

{
  nix = {
    settings = {
      # 二进制缓存：nyx（CachyOS）+ SJTU（国内）+ cache.nixos.org（兜底）
      substituters = [
        "https://nyx-cache.chaotic.cx/"
        "https://mirror.sjtu.edu.cn/nix-channels/store"
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
      # GC 误伤防护：keep-outputs 保留构建产物；min-free/max-free 磁盘将满自动提前清理
      # (REF:2026-08-29-gc-missing-toplevel)
      keep-outputs = true;
      min-free = "2G";
      max-free = "8G";
      # GitHub token 由 modules/secrets.nix 的 sops 模板注入（NIX_CONFIG env file）
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      connect-timeout = 5;
      stalled-download-timeout = 10;
      http-connections = 50;
      max-substitution-jobs = 20;
      warn-dirty = false;
    };
    registry.nixpkgs.to = {
      type = "git";
      url = "https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git";
      ref = "nixos-unstable";
    };
  };

  # nix-daemon 下载走代理（地址单一来源：modules/proxy.nix）
  systemd.services.nix-daemon.environment = {
    http_proxy = config.proxy.address;
    https_proxy = config.proxy.address;
    all_proxy = config.proxy.address;
    # Go 模块国内代理：sops-install-secrets/DMS 现场编译需要 (REF:2026-08-30-goproxy)
    GOPROXY = "https://goproxy.cn,direct";
  };

  # 客户端侧 GOPROXY（nix develop / nix shell 内 buildGoModule 场景）
  environment.sessionVariables.GOPROXY = "https://goproxy.cn,direct";

  # Chaotic-Nyx（CachyOS 高性能包）
  chaotic.nyx = {
    overlay.enable = true;
    cache.enable = false; # 缓存由本文件 substituters 全权管理，避免重复
  };

  # 客户端工具：nix-ld / nix-index
  programs = {
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
        libice # omencore-gui 依赖
        libsm # omencore-gui 依赖
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
