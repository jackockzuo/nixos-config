{ pkgs, ... }: {

  # 开启 nix-ld
  programs.nix-ld.enable = true;

  # 这一套组合拳基本覆盖了 99% 的二进制程序需求
  programs.nix-ld.libraries = with pkgs; [
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
}
