# ============================================================
# omencore 打包定义（唯一来源，CLI-only）
# 来源：GitHub 官方 release 二进制 zip（v${version}），自包含 fetchzip
# 原理：.NET 8（C#），上游发布 self-contained 单文件二进制
# 2026-09-03 CLI 瘦身：仅装 omencore-cli（无需同目录 *.so，Skia/HarfBuzz 仅 GUI 用）
# 为什么不做 autoPatchelf/patchelf：
#   .NET 单文件 apphost 是"ELF + 内嵌 bundle"，patchelf 会破坏 bundle 偏移
#   (REF:2026-08-23-omencore-patchelf)。
# 滚动更新（直接拉最新 release）：nix-update --flake omencore --version=stable
#   （或 nix run .#omencore-update）：自动改写 version、重算下面的 hash
# 接入：flake.nix overlays.default → pkgs.omencore → hosts/omen/omencore.nix
# ============================================================
{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:

let
  version = "4.3.1";
in
stdenvNoCC.mkDerivation {
  pname = "omencore";
  inherit version;

  src = fetchzip {
    url = "https://github.com/theantipopau/omencore/releases/download/v${version}/OmenCore-${version}-linux-x64.zip";
    hash = "sha256-tW2vU688RgODnBI2SG3PAhQM9RSrgpfnFN/p4Grksuc=";
    stripRoot = false; # 上游 zip 是扁平结构（文件直接在根）
  };

  # src 已由 fetchzip 解包：直接是含 omencore-cli / omencore-gui / *.so 的目录
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 "$src/omencore-cli" $out/bin/omencore-cli

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=stable" ];
  };

  meta = with lib; {
    description = "Advanced performance control for HP OMEN laptops (EC power unlock/fan/perf; CLI)";
    homepage = "https://github.com/theantipopau/omencore";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "omencore-cli";
  };
}
