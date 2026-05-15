#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMBINED="$ROOT/.archives/combined.doccarchive"

SERVER_PID=""
SERVER_PORT="${1:-8080}"
PREVIEW_DIR=""

cleanup() {
    trap - EXIT INT TERM HUP

    [[ -n "$SERVER_PID" ]]  && kill "$SERVER_PID" 2>/dev/null || true
    [[ -n "$PREVIEW_DIR" ]] && rm -rf "$PREVIEW_DIR"
}

trap cleanup EXIT INT TERM HUP

if [[ ! -d "$COMBINED" ]]; then
    "$(dirname "$0")/build-combined-docs.sh"
fi

PREVIEW_DIR=$(mktemp -d)

echo "=== Transforming for local preview ==="

xcrun docc process-archive transform-for-static-hosting \
           --output-path "$PREVIEW_DIR"                 \
           "$COMBINED"

python3 -m http.server   \
        --bind 127.0.0.1 \
        --directory "$PREVIEW_DIR" "$SERVER_PORT" &

SERVER_PID=$!

sleep 2

open "http://127.0.0.1:${SERVER_PORT}/documentation/"

wait "$SERVER_PID" || true
