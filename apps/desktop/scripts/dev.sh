#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly DEV_PORT=5188
VELOX_DIR="$ROOT/desktop-velox"
VELOX_CLI="$VELOX_DIR/.build/checkouts/velox/.build/debug/velox"

free_dev_port() {
  local pids
  pids="$(lsof -nP -iTCP:"$DEV_PORT" -sTCP:LISTEN -t 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    echo "[dev] port ${DEV_PORT} in use; stopping stale listener(s): ${pids}"
    # shellcheck disable=SC2086
    kill $pids 2>/dev/null || true
    sleep 0.5
  fi
}

stop_stale_app() {
  pkill -x CleanSpaceDesktop 2>/dev/null || true
  pkill -x Cleaning 2>/dev/null || true
}

build_velox_cli() {
  (cd "$VELOX_DIR/.build/checkouts/velox" && swift build --product velox)
}

run_velox() {
  (cd "$VELOX_DIR" && "$VELOX_CLI" "$@")
}

cd "$ROOT"
stop_stale_app
free_dev_port

echo "[dev] Vite ${DEV_PORT} + Velox window…"
build_velox_cli
exec run_velox dev CleanSpaceDesktop
