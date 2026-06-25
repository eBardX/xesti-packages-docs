#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECKOUTS="$ROOT/.build/checkouts"
ARCHIVES="$ROOT/.archives"
COMBINED="$ARCHIVES/combined.doccarchive"

echo "=== Resolving dependencies ==="

# Force all packages to be checked out fresh.
rm -rf "$ROOT/Package.resolved" "$CHECKOUTS"

swift package --package-path "$ROOT" resolve

# Compute build order by parsing inter-Xesti dependencies from each checkout’s
# Package.swift and topologically sorting the result (Kahn’s algorithm).
# Requires Swift, which is already a hard dependency of this repo. To add or
# remove a package, edit Package.swift only — no changes needed here.
ORDERED=()

while IFS= read -r pkg; do
    ORDERED+=("$pkg")
done < <(swift "$(dirname "$0")/toposort-packages.swift" "$ROOT/Package.swift" "$CHECKOUTS")

rm -rf "$ARCHIVES"
mkdir -p "$ARCHIVES"

BUILT_ARCHIVES=()

for pkg in "${ORDERED[@]}"; do
    echo "=== Building archives: $pkg ==="

    # Discover targets by finding all Sources subdirectories that contain a
    # Documentation.docc bundle. Sorting ensures a stable, alphabetical order,
    # which places the primary target (same name as the package) first.
    TARGETS=()

    while IFS= read -r docc_dir; do
        TARGETS+=("$(basename "$(dirname "$docc_dir")")")
    done < <(find "$CHECKOUTS/$pkg/Sources" -name "Documentation.docc" -type d | sort)

    for target in "${TARGETS[@]}"; do
        echo "--- Building archive: $target ---"

        ARCHIVE="$ARCHIVES/$target.doccarchive"
        SYMBOL_GRAPHS_RAW=$(mktemp -d)
        SYMBOL_GRAPHS="$ARCHIVES/$target.symbols"

        mkdir -p "$SYMBOL_GRAPHS"

        swift build --package-path "$CHECKOUTS/$pkg" \
                    --target "$target"               \
                    -Xswiftc -emit-symbol-graph      \
                    -Xswiftc -emit-symbol-graph-dir  \
                    -Xswiftc "$SYMBOL_GRAPHS_RAW"

        find "$SYMBOL_GRAPHS_RAW" -name "${target}*.symbols.json" \
            -exec cp {} "$SYMBOL_GRAPHS/" \;

        rm -rf "$SYMBOL_GRAPHS_RAW"

        # Always enable external link support so later packages can link here.
        # Pass every already-built archive so DocC can resolve cross-package
        # links, including earlier targets within the same package.
        DOCC_FLAGS=(--enable-experimental-external-link-support)

        if [[ ${#BUILT_ARCHIVES[@]} -gt 0 ]]; then
            for dep in "${BUILT_ARCHIVES[@]}"; do
                DOCC_FLAGS+=(--dependency "$dep")
            done
        fi

        xcrun docc convert "$CHECKOUTS/$pkg/Sources/$target/Documentation.docc" \
                   --additional-symbol-graph-dir "$SYMBOL_GRAPHS"                \
                   --fallback-display-name "$target"                             \
                   --fallback-bundle-identifier "$target"                        \
                   --output-path "$ARCHIVE"                                      \
                   "${DOCC_FLAGS[@]}"

        BUILT_ARCHIVES+=("$ARCHIVE")
    done
done

echo "=== Merging archives ==="

xcrun docc merge "${BUILT_ARCHIVES[@]}"                     \
           --synthesized-landing-page-kind ""               \
           --synthesized-landing-page-name "Xesti Packages" \
           --synthesized-landing-page-topics-style list     \
           --output-path "$COMBINED"

echo "=== Archives: ${BUILT_ARCHIVES[*]} ==="
