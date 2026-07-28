#!/usr/bin/env bash
# 防止用户可见文案以 CJK 字面量写回 SwiftUI / Alert 等调用中；应使用 L10n + Localizable.strings。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/apps/desktop/desktop-velox/Sources/CleanSpaceKit"

if ! command -v rg >/dev/null 2>&1; then
  echo "check-swift-ui-l10n: 跳过（未安装 ripgrep / rg）"
  exit 0
fi

if [[ ! -d "$SRC" ]]; then
  echo "check-swift-ui-l10n: 跳过（未找到 CleanSpaceKit 源码）"
  exit 0
fi

EXCLUDE=(--glob '!**/Localization/L10n.swift')

PATTERN='(?x)
  (?:^|[({\s])
  (?:Text|Button|Label|Section|navigationTitle|LabeledContent|ContentUnavailableView|TableColumn|Picker)
  \s*\(\s*"[^"]*\p{Han}[^"]*"
  |
  \.alert\s*\(\s*"[^"]*\p{Han}[^"]*"
  |
  title:\s*"[^"]*\p{Han}[^"]*"
  |
  placeholder:\s*"[^"]*\p{Han}[^"]*"
'

if rg --pcre2 -n "${EXCLUDE[@]}" --glob '*.swift' "$PATTERN" "$SRC" 2>/dev/null; then
  echo ""
  echo "check-swift-ui-l10n: 发现 Swift 源码中含汉字的 UI 字符串字面量。"
  echo "请将文案写入 CleanSpaceKit/Resources/*/Localizable.strings，并在代码中使用 L10n.*。"
  exit 1
fi

exit 0
