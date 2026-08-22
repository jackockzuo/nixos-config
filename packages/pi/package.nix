# ============================================================
# pi-coding-agent 包定义（唯一来源）
# 被两处引用：flake perSystem packages / 系统 nixpkgs.overlays
# 原理（buildNpmPackage → fetchNpmDeps，见 flake.nix 注释）：
#   npm-deps 阶段独立跑 npm 生成依赖缓存（fixed-output 允许联网），
#   npmDepsHash 校验；npmConfigHook 校验 src lock 与缓存 lock 一致。
# ⚠️ 上游 npm 发布包的 shrinkwrap 缺 6 个 @earendil-works/* 子包 integrity
#    → npm-deps 解析 panic；postPatch 用本目录 vendor 的完整
#    package-lock.json（263 条 integrity 全齐）替换坏锁（方案 A）。
# 升级：更新 version/src sha256 → npm install --package-lock-only 重新
#   生成本目录 lock → nix build 报 fakeHash 拿新 npmDepsHash。
# ============================================================
{ pkgs }:
pkgs.buildNpmPackage {
  pname = "pi-coding-agent";
  version = "0.84.2";
  src = builtins.fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-0.84.2.tgz";
    sha256 = "1ylglvqwga8scrb4f7vx79ay6dbl8amk7gy7fh0iy30sgg6rkf4m";
  };
  # 依赖全为纯 JS（@earendil-works/* 子包 + 标准库），无原生编译
  postPatch = ''
    rm -f npm-shrinkwrap.json
    cp ${./package-lock.json} package-lock.json
  '';
  npmDepsHash = "sha256-gafYJMTl6IByh45JO5IZe3AKIB13k+Hs/NI/uRN9/os="; # 2026-08-22 实测
  dontNpmBuild = true; # tarball 已含 dist/（prepublishOnly 构建过）
}
