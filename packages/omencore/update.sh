#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# omencore 滚动更新（直接拉最新 release）
# 用法（在仓库根目录执行）：nix run .#omencore-update
#                或 bash packages/omencore/update.sh [repo-root]
# 作用：
#   nix-update 读取 packages/omencore/package.nix 的 version，
#   查 GitHub 最新稳定 release（theantipopau/omencore），
#   直接改写 version 并自动重算 fetchzip 的 hash。
# 之后 git add flake.lock packages/omencore/package.nix 提交即可。
# ============================================================

repo_root="${1:-$PWD}"
cd "$repo_root"

if [[ ! -f flake.nix ]]; then
  echo "错误：$repo_root 不是仓库根目录（无 flake.nix）。请在仓库根目录运行。" >&2
  exit 1
fi

echo "==> 更新 omencore 到最新 release ..."
nix-update --flake omencore --version=stable

echo "==> 构建验证 ..."
nix build .#omencore --no-link --print-out-paths

echo
echo "✅ 完成。提交：git add flake.lock packages/omencore/package.nix"
