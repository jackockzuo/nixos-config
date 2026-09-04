# ============================================================
# omencore 打包定义（唯一来源，CLI-only）
# 来源：flake.nix inputs.omencore（官方 release 二进制 zip，v${version}）
# 原理：.NET 8（C#），上游发布 self-contained 单文件二进制
# 2026-09-03 CLI 瘦身：实测 omencore-cli 单文件独立运行（无需同目录 *.so，
#   Skia/HarfBuzz 仅为 GUI 渲染用）→ 不再安装 omencore-gui / 桌面项 / 图标。
# 为什么不做 autoPatchelf/patchelf：
#   .NET 单文件 apphost 是"ELF + 内嵌 bundle"，patchelf 会破坏 bundle 偏移
#   (REF:2026-08-23-omencore-patchelf)。
# 滚动更新：nix run .#omencore-update（见 packages/omencore/update.sh）
# 接入：flake.nix overlays.default → pkgs.omencore → hosts/omen/omencore.nix
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

    mkdir -p $out/bin
    install -m755 "$src/omencore-cli" $out/bin/omencore-cli

    runHook postInstall
  '';

  meta = with lib; {
    description = "Advanced performance control for HP OMEN laptops (EC power unlock/fan/perf; CLI)";
    homepage = "https://github.com/theantipopau/omencore";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "omencore-cli";
  };
}
