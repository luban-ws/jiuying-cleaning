#!/usr/bin/env bash
# 从 icon.svg 生成 AppIcon-1024.png；在 SwiftPM 构建前由 npm / bundle 脚本调用。
# 若本机有 rsvg-convert（Homebrew librsvg）则始终从矢量重新导出；否则保留仓库内已有 PNG，不中断构建。

set -euo pipefail

DESIGN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SVG="${DESIGN_DIR}/icon.svg"
OUT_DIR="${DESIGN_DIR}/../Sources/CleanSpaceKit/Resources/Assets.xcassets/AppIcon.appiconset"
OUT_PNG="${OUT_DIR}/AppIcon-1024.png"

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
  exit 0
fi

if [[ -f "${OUT_PNG}" ]]; then
  exit 0
fi

echo "design: 未找到 rsvg-convert 且缺少 AppIcon-1024.png；请安装 librsvg 或将 PNG 提交到仓库。" >&2
exit 1
