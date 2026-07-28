#!/usr/bin/env bash
# 通过 Velox release 构建可双击的 .app（替代已移除的 SwiftUI 可执行目标）。
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"
pnpm build:app

echo "bundle-mac-app: 已生成 apps/desktop/desktop-velox/dist/CleanSpaceDesktop.app"
