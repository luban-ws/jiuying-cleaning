#!/usr/bin/env bash
# 本地开发：debug 构建、打包 .app（含图标）、打开 Cleaner 窗口。
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 避免旧实例占着菜单栏或造成「像没启动」。
pkill -f "${REPO_ROOT}/app/.build/.*/CleanSpace" 2>/dev/null || true
pkill -x CleanSpace 2>/dev/null || true

"${REPO_ROOT}/scripts/bundle-mac-app.sh" debug

readonly APP_DIR="$(
  cd "${REPO_ROOT}/app"
  swift build -c debug --show-bin-path
)/CleanSpace.app"

if [[ ! -d "${APP_DIR}" ]]; then
  echo "app:dev: 未找到 ${APP_DIR}" >&2
  exit 1
fi

open "${APP_DIR}"
echo "app:dev: 已启动 ${APP_DIR}"
