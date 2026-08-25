# ============================================================
# omencore 打包定义（唯一来源）
# 来源：flake.nix inputs.omencore（官方 release 二进制 zip，v${version}）
# 原理：.NET 8 + Avalonia（C#），上游发布 self-contained 单文件二进制：
#       omencore-cli（控制台，InvariantGlobalization）+ omencore-gui（GUI）
#       + 3 个 SkiaSharp/HarfBuzzSharp/MonoPosix 原生 .so。
# 为什么不 buildDotnetModule 源码编译：Avalonia + 大量 NuGet 依赖在 Nix 下
#       极重（SkiaSharp 原生库/ICU/X11 依赖链），上游官方 release 即为自包含
#       产物，本文件与 Arch AUR 的 omencore-bin 包同思路（仅 x86_64-linux）。
# 🔴 为什么不做 autoPatchelf/patchelf：
#   - .NET 单文件 apphost 是"ELF + 内嵌 bundle"，bundle 头记录文件尾偏移；
#     patchelf 追加段（写 interpreter/rpath）会破坏该偏移 → 启动即
#     "Arithmetic overflow while reading bundle"（2026-08-23 实测）。
#   - 本机已启用 programs.nix-ld（modules/nix.nix），/lib64/ld-linux-x86-64.so.2
#     → nix-ld，且 libraries 已含 zlib/icu/fontconfig/libx11/libxext/libxi/
#     libxrandr/gtk3 等全部运行时依赖 → 原生二进制直接可跑，无需打补丁。
#   - 单机配置（STANDARDS §1：单机 omen），nix-ld 即本仓库"跑第三方二进制"通道。
# 滚动更新：nix run .#omencore-update（见 packages/omencore/update.sh）
# 接入：flake.nix overlays.default → pkgs.omencore → modules/omencore.nix
# ============================================================
{
  lib,
  stdenvNoCC,
  src,
}:

let
  version = "4.1.7"; # 滚动更新时由 update.sh 自动改
in
stdenvNoCC.mkDerivation {
  pname = "omencore";
  inherit version src;

  # flake 输入（omercore，flake=false，tarball 类型）已解包：
  # src 直接是含 omencore-cli / omencore-gui / *.so 的目录，无需 unpack/unzip
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/applications $out/share/pixmaps
    install -m755 "$src/omencore-cli" $out/bin/omencore-cli
    install -m755 "$src/omencore-gui" $out/bin/omencore-gui

    # SkiaSharp/HarfBuzzSharp/MonoPosix 原生库：.NET 的 DllImport 从可执行文件
    # 同目录解析（实测必须与二进制同目录，否则 GUI 报 unable to load libSkiaSharp）
    install -m755 "$src/libSkiaSharp.so" $out/bin/libSkiaSharp.so
    install -m755 "$src/libHarfBuzzSharp.so" $out/bin/libHarfBuzzSharp.so
    install -m755 "$src/libMonoPosixHelper.so" $out/bin/libMonoPosixHelper.so

    # 桌面项（niri 的 launcher 经 XDG_DATA_DIRS 读取；Icon=omencore 对应下面 pixmaps）
    # Exec 用 root 启动器（omencore-gui-root）：自动 sudo 免密 + 保留会话环境，
    # 让 GUI 以 root 运行（全部硬件功能可用）。普通用户版仍可手动跑 omencore-gui。
    cat > $out/share/applications/omencore.desktop <<'EOF'
    [Desktop Entry]
    Type=Application
    Name=OmenCore
    GenericName=Laptop Control Center
    Comment=Control center for HP OMEN and Victus gaming laptops (fan/RGB/perf)
    Exec=omencore-gui-root
    Icon=omencore
    Terminal=false
    Categories=System;Settings;HardwareSettings;
    StartupNotify=true
    EOF

    # 图标 vendor 进仓库（packages/omencore/omencore.png），不随版本滚动、无需联网
    install -Dm644 ${./omencore.png} $out/share/pixmaps/omencore.png

    runHook postInstall
  '';

  meta = with lib; {
    description = "Advanced performance control for HP OMEN laptops (fan/RGB/perf; CLI + GUI)";
    homepage = "https://github.com/theantipopau/omencore";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "omencore-cli";
  };
}
