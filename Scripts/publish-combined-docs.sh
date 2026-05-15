#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMBINED="$ROOT/.archives/combined.doccarchive"
DOCS="$ROOT/docs"

"$(dirname "$0")/build-combined-docs.sh"

echo "=== Transforming for static hosting ==="

rm -rf "$DOCS"

xcrun docc process-archive transform-for-static-hosting \
           --hosting-base-path xesti-packages-docs      \
           --output-path "$DOCS"                        \
           "$COMBINED"

echo ""
echo "=== Documentation generated at: $DOCS ==="
