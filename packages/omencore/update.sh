#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# omencore 滚动更新脚本
# 用法（在仓库根目录执行）：nix run .#omencore-update
#                或 bash packages/omencore/update.sh [repo-root]
# 作用：
#   1. 查 GitHub 最新 release（theantipopau/omencore）
#   2. 改 flake.nix 的 inputs.omencore URL 版本号 + package.nix 的 version
#   3. nix flake lock --update-input omencore（自动重算 zip 的 narHash）
#   4. nix build .#omencore 验证
# 之后 git add flake.nix flake.lock packages/omencore/package.nix 并提交即可。
# ============================================================

# repo 根目录：默认当前目录（nix run 会保留 cwd），也可显式传参覆盖
repo_root="${1:-$PWD}"
cd "$repo_root"

if [[ ! -f flake.nix ]]; then
  echo "错误：$repo_root 不是仓库根目录（无 flake.nix）。请在仓库根目录运行。" >&2
  exit 1
fi

api="https://api.github.com/repos/theantipopau/omencore/releases/latest"

echo "==> 查询最新 release..."
latest_json="$(curl -fsSL "$api")"
new_version="$(printf '%s' "$latest_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))')"

old_version="$(sed -n 's/^[[:space:]]*version = "\([0-9][0-9.]*\)";.*/\1/p' packages/omencore/package.nix | head -1)"

if [[ -z "$old_version" || -z "$new_version" ]]; then
  echo "错误：无法解析版本号（old=$old_version new=$new_version）" >&2
  exit 1
fi

if [[ "$new_version" == "$old_version" ]]; then
  echo "✅ 已是最新 v$old_version，无需更新。"
  exit 0
fi

echo "==> 更新 omencore：v$old_version → v$new_version"

# flake.nix：URL 里的两处版本号（/download/vX.Y.Z/ 与 OmenCore-X.Y.Z-linux-x64.zip）
sed -i \
  -e "s#releases/download/v${old_version}/#releases/download/v${new_version}/#" \
  -e "s#OmenCore-${old_version}-linux-x64.zip#OmenCore-${new_version}-linux-x64.zip#" \
  flake.nix
# package.nix：version 声明（let version = "X.Y.Z";）
sed -i "s#version = \"${old_version}\"#version = \"${new_version}\"#" packages/omencore/package.nix

echo "==> 刷新 flake.lock（重算 omencore zip 的 narHash）..."
nix flake lock --update-input omencore

echo "==> 构建验证..."
nix build .#omencore --no-link --print-out-paths

echo
echo "✅ 已更新到 v$new_version。"
echo "   提交：git add flake.nix flake.lock packages/omencore/package.nix"
