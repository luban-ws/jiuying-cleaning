#!/usr/bin/env bash
# 从 icon.svg 生成 AppIcon-1024.png 与访达用 AppIcon.icns。
# 在 SwiftPM 构建前由 pnpm（build:app）/ bundle 脚本调用。
# 若本机有 rsvg-convert（Homebrew librsvg）则始终从矢量重新导出；否则保留仓库内已有 PNG，不中断构建。

set -euo pipefail

DESIGN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SVG="${DESIGN_DIR}/icon.svg"
OUT_DIR="${DESIGN_DIR}/../app/Sources/CleanSpaceKit/Resources/Assets.xcassets/AppIcon.appiconset"
OUT_PNG="${OUT_DIR}/AppIcon-1024.png"
OUT_ICNS="${DESIGN_DIR}/../app/Support/AppIcon.icns"

mkdir -p "${OUT_DIR}"

if [[ ! -f "${ICON_SVG}" ]]; then
  echo "design: 缺少 icon.svg，跳过" >&2
  exit 0
fi

RSVG=""
for c in rsvg-convert /opt/homebrew/bin/rsvg-convert /usr/local/bin/rsvg-convert; do
  if command -v "${c}" >/dev/null 2>&1; then
    RSVG="${c}"
    break
  fi
done

if [[ -n "${RSVG}" ]]; then
  "${RSVG}" -w 1024 -h 1024 -o "${OUT_PNG}" "${ICON_SVG}"
  echo "design: 已生成 ${OUT_PNG}"
elif [[ ! -f "${OUT_PNG}" ]]; then
  echo "design: 未找到 rsvg-convert 且缺少 AppIcon-1024.png；请安装 librsvg 或将 PNG 提交到仓库。" >&2
  exit 1
fi

# macOS .app 访达图标需要 .icns（Assets.xcassets 仅随 SwiftPM 资源包，不会自动成为 bundle 图标）
if [[ -f "${OUT_PNG}" ]] && command -v iconutil >/dev/null 2>&1 && command -v sips >/dev/null 2>&1; then
  ICONSET_DIR="$(mktemp -d).iconset"
  trap 'rm -rf "${ICONSET_DIR}"' EXIT
  mkdir -p "${ICONSET_DIR}"

  declare -a ICONSET_ENTRIES=(
    "16:icon_16x16.png"
    "32:icon_16x16@2x.png"
    "32:icon_32x32.png"
    "64:icon_32x32@2x.png"
    "128:icon_128x128.png"
    "256:icon_128x128@2x.png"
    "256:icon_256x256.png"
    "512:icon_256x256@2x.png"
    "512:icon_512x512.png"
    "1024:icon_512x512@2x.png"
  )

  for entry in "${ICONSET_ENTRIES[@]}"; do
    size="${entry%%:*}"
    filename="${entry##*:}"
    sips -z "${size}" "${size}" "${OUT_PNG}" --out "${ICONSET_DIR}/${filename}" >/dev/null
  done

  iconutil -c icns "${ICONSET_DIR}" -o "${OUT_ICNS}"
  echo "design: 已生成 ${OUT_ICNS}"
fi
