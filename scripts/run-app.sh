#!/usr/bin/env bash
# 从仓库根目录的 package.json 调用；也可直接执行，不依赖当前工作目录。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/app"
exec swift run CleanSpace "$@"
