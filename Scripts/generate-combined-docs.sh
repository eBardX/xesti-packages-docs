#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECKOUTS="$ROOT/.build/checkouts"
ARCHIVES="$ROOT/.archives"
COMBINED="$ARCHIVES/combined.doccarchive"
DOCS="$ROOT/docs"

echo "=== Resolving dependencies ==="

swift package --package-path "$ROOT" resolve

# Compute build order by parsing inter-Xesti dependencies from each checkout's
# Package.swift and topologically sorting the result (Kahn's algorithm).
# Requires Swift, which is already a hard dependency of this repo.
# To add or remove a package, edit Package.swift only — no changes needed here.
ORDERED=()

while IFS= read -r pkg; do
    ORDERED+=("$pkg")
done < <(swift "$(dirname "$0")/toposort-packages.swift" "$ROOT/Package.swift" "$CHECKOUTS")

rm -rf "$ARCHIVES"
mkdir -p "$ARCHIVES"

BUILT_ARCHIVES=()

for pkg in "${ORDERED[@]}"; do
    echo "=== Building archive: $pkg ==="

    ARCHIVE="$ARCHIVES/$pkg.doccarchive"

    # Always enable external link support so later packages can link here. Pass
    # every already-built archive so DocC can resolve cross-package links.
    DOCC_FLAGS=(--enable-experimental-external-link-support)

    if [[ ${#BUILT_ARCHIVES[@]} -gt 0 ]]; then
        for dep in "${BUILT_ARCHIVES[@]}"; do
            DOCC_FLAGS+=(--dependency "$dep")
        done
    fi

    swift package --package-path "$CHECKOUTS/$pkg"           \
                  --allow-writing-to-directory "$ARCHIVES"   \
                  generate-documentation                     \
                  --disable-indexing                         \
                  --output-path "$ARCHIVE"                   \
                  --target "$pkg"                            \
                  -- "${DOCC_FLAGS[@]}"

    BUILT_ARCHIVES+=("$ARCHIVE")
done

echo "=== Merging archives ==="

xcrun docc merge "${BUILT_ARCHIVES[@]}"                      \
           --synthesized-landing-page-name "Xesti Packages"  \
           --synthesized-landing-page-kind "Package"         \
           --output-path "$COMBINED"

echo "=== Transforming for static hosting ==="

rm -rf "$DOCS"

xcrun docc process-archive transform-for-static-hosting \
           --hosting-base-path xesti-packages-docs      \
           --output-path "$DOCS"                        \
           "$COMBINED"

echo ""
echo "=== Documentation generated at: $DOCS ==="
echo "=== Packages: ${ORDERED[*]} ==="
