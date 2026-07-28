#!/usr/bin/env bash
# 本地开发：打开 Velox dev 构建的 Cleaning Dev.app。
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"
pnpm open:app:dev
