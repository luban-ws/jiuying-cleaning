#!/usr/bin/env bash
# Legacy SwiftUI entry (Velox desktop is default via pnpm dev).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/legacy"
exec swift run CleanSpace "$@"
