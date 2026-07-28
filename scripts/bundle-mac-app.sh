#!/usr/bin/env bash
# 将 swift build 产物打成可在访达中双击的 .app（无需 Xcode.app）。
set -euo pipefail

readonly CONFIG="${1:-release}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly APP_ROOT="${REPO_ROOT}/legacy"
readonly SUPPORT_DIR="${APP_ROOT}/Support"
readonly INFO_PLIST="${SUPPORT_DIR}/Info.plist"
readonly BUNDLE_ID_SUFFIX="CleanSpace_CleanSpaceKit.bundle"

cd "${APP_ROOT}"

if [[ ! -f "${INFO_PLIST}" ]]; then
  echo "bundle-mac-app: 缺少 ${INFO_PLIST}" >&2
  exit 1
fi

node "${REPO_ROOT}/design/generate-app-icon.mjs"

swift build -c "${CONFIG}"

readonly BIN_DIR="$(swift build -c "${CONFIG}" --show-bin-path)"
readonly EXEC_SRC="${BIN_DIR}/CleanSpace"
readonly RES_SRC="${BIN_DIR}/${BUNDLE_ID_SUFFIX}"
readonly APP_DIR="${BIN_DIR}/CleanSpace.app"

if [[ ! -x "${EXEC_SRC}" ]]; then
  echo "bundle-mac-app: 未找到可执行文件 ${EXEC_SRC}" >&2
  exit 1
fi
if [[ ! -d "${RES_SRC}" ]]; then
  echo "bundle-mac-app: 未找到资源包 ${RES_SRC}" >&2
  exit 1
fi

rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp "${EXEC_SRC}" "${APP_DIR}/Contents/MacOS/CleanSpace"
cp "${INFO_PLIST}" "${APP_DIR}/Contents/Info.plist"
if [[ -f "${SUPPORT_DIR}/AppIcon.icns" ]]; then
  cp "${SUPPORT_DIR}/AppIcon.icns" "${APP_DIR}/Contents/Resources/"
fi
cp -R "${RES_SRC}" "${APP_DIR}/Contents/Resources/"

chmod +x "${APP_DIR}/Contents/MacOS/CleanSpace"

echo "bundle-mac-app: 已生成 ${APP_DIR}"
