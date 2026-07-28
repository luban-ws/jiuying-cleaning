#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VELOX_DIR="$ROOT/desktop-velox"
VELOX_CLI="$VELOX_DIR/.build/checkouts/velox/.build/debug/velox"

build_velox_cli() {
  (cd "$VELOX_DIR/.build/checkouts/velox" && swift build --product velox)
}

run_velox() {
  (cd "$VELOX_DIR" && "$VELOX_CLI" "$@")
}

cd "$ROOT"
build_velox_cli
export VELOX_BUNDLE_CONFIGURATION=release
exec run_velox build --bundle CleanSpaceDesktop
