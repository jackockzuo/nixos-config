# ============================================================
# CI 占位包（fcclientPkg 的 override-input 目标）
# 用途：GitHub Actions 环境没有仓库外 ~/Documents/nix-packaging/fcclient，
#       CI 用 `--override-input fcclientPkg ./.ci/fcclient-placeholder` 让
#       flake check 能 eval packages.fcclient（不真正构建，仅求值占位）。
# 本机构建 fcclient 时此文件不参与（flake.lock 指向真实路径）。
# ============================================================
{ pkgs }:
pkgs.hello
