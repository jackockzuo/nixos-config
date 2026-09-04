# ============================================================
# omencore 打包定义（唯一来源）
# 来源：flake.nix inputs.omencore（官方 release 二进制 zip，v${version}）
# 原理：.NET 8 + Avalonia（C#），上游发布 self-contained 单文件二进制
# 为什么不做 autoPatchelf/patchelf：
#   .NET 单文件 apphost 是"ELF + 内嵌 bundle"，patchelf 会破坏 bundle 偏移
#   (REF:2026-08-23-omencore-patchelf)。本机已启用 nix-ld，原生二进制直接可跑
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
