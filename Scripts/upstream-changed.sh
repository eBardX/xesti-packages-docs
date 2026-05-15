#!/bin/bash
#
# Without arguments: exits 0 if any upstream package's main branch has
# changed since the last recorded build (or if no record exists yet);
# exits 1 if all packages match the record (skip the build).
#
# With --record: writes the current upstream SHAs to .upstream-shas and
# exits 0. Call this after a successful publish to update the baseline.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHA_FILE="$ROOT/.upstream-shas"
RECORD=0

if [[ "${1:-}" == "--record" ]]; then
    RECORD=1
fi

# Extract all HTTPS package URLs from Package.swift.

URLS=()

while IFS= read -r url; do
    URLS+=("$url")
done < <(grep -oE '"https://[^"]+"' "$ROOT/Package.swift" | tr -d '"')

if [[ $RECORD -eq 1 ]]; then
    : > "$SHA_FILE"

    for url in "${URLS[@]}"; do
        sha=$(git ls-remote "$url" refs/heads/main | awk '{print $1}')
        echo "$url $sha" >> "$SHA_FILE"
    done

    echo "=== Recorded upstream SHAs ==="

    cat "$SHA_FILE"

    exit 0
fi

if [[ ! -f "$SHA_FILE" ]]; then
    echo "No upstream SHA record — build needed."
    exit 0
fi

for url in "${URLS[@]}"; do
    current=$(git ls-remote "$url" refs/heads/main | awk '{print $1}')
    recorded=$(awk -v u="$url" '$1 == u { print $2 }' "$SHA_FILE")

    if [[ "$current" != "$recorded" ]]; then
        echo "Changed: $(basename "$url" .git) ($recorded -> $current)"
        exit 0
    fi
done

echo "All upstream packages unchanged — skipping build."

exit 1
