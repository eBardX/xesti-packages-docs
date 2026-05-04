# xesti-packages-docs: Combined DocC Documentation Site

## Overview

All Xesti packages are fully documented with DocC comments but each currently maintains its own
per-repo GitHub Pages site. This proposal describes creating a single unified documentation site
at `https://ebardx.github.io/xesti-packages-docs/` that consolidates the API reference for all
packages into one navigable, cross-linked DocC archive.

---

## Repository

### Location

A new subdirectory `Tools/xesti-packages-docs/` will serve as both the umbrella Swift package
and the GitHub repository for the combined docs site. Because `Tools/` is not itself a git
repository, initializing a repo inside `xesti-packages-docs/` creates a clean, standalone repo
with no nesting complications.

```
Tools/
├── xesti-packages-docs/   ← new git repo (this proposal)
│   ├── .github/
│   │   └── workflows/
│   │       └── generate-combined-docs.yml
│   ├── Scripts/
│   │   └── generate-combined-docs.sh
│   ├── .gitignore
│   ├── Package.swift
│   └── docs/              ← generated output (GitHub Pages source)
├── XestiMarkov/           ← existing repo, unchanged
├── XestiNetwork/          ← existing repo, unchanged
...
```

### Remote

Create a new public GitHub repository named `xesti-packages-docs` under the `eBardX` account.
GitHub Pages will be configured to serve from the `docs/` folder on the `main` branch, giving
the site URL:

```
https://ebardx.github.io/xesti-packages-docs/
```

---

## Umbrella Package

`Package.swift` has no source targets — it exists solely to pin and resolve all Xesti packages
so `swift package resolve` populates `.build/checkouts/` with their `main` branches. The
`Scripts/generate-combined-docs.sh` then drives doc generation directly from those checkouts. Each Xesti
package brings its own `swift-docc-plugin` dependency, so the umbrella does not need to declare
it.

```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "xesti-packages-docs",
    dependencies: [
        .package(url: "https://github.com/eBardX/XestiMarkov.git",   branch: "main"),
        .package(url: "https://github.com/eBardX/XestiNetwork.git",  branch: "main"),
        .package(url: "https://github.com/eBardX/XestiNumbers.git",  branch: "main"),
        .package(url: "https://github.com/eBardX/XestiSexp.git",     branch: "main"),
        .package(url: "https://github.com/eBardX/XestiText.git",     branch: "main"),
        .package(url: "https://github.com/eBardX/XestiTokens.git",   branch: "main"),
        .package(url: "https://github.com/eBardX/XestiTools.git",    branch: "main"),
        .package(url: "https://github.com/eBardX/XestiXML.git",      branch: "main"),
    ],
    targets: []
)
```

Because SPM resolves the full transitive dependency graph, each Xesti package's own dependencies
(BigInt, swift-numerics, swift-argument-parser, ZIPFoundation, etc.) are also fetched
automatically. No additional entries are needed for those.

---

## Generating Documentation

### Command

Run this from inside `Tools/xesti-packages-docs/`:

```bash
./Scripts/generate-combined-docs.sh
```

### How it works

`Scripts/generate-combined-docs.sh` uses a three-stage pipeline:

1. **Resolve** — `swift package resolve` populates `.build/checkouts/` with the `main` branch
   of each Xesti package.

2. **Build archives** — For each package, `swift package generate-documentation` is run from
   its checkout directory, producing a `.doccarchive` in `.archives/`. The build order follows
   the inter-Xesti dependency graph (XestiText → XestiTools → everything else → XestiSexp).

3. **Merge + transform** — `docc merge` combines all eight archives into a single
   `combined.doccarchive` with a synthesized "Xesti Packages" landing page and unified
   navigation. `docc process-archive transform-for-static-hosting` then converts that combined
   archive to the flat `docs/` tree served by GitHub Pages.

Note: cross-package DocC symbol links (e.g., `<doc:XestiTools/SomeType>` referenced from
`XestiMarkov`) do not resolve in this pipeline because each package is built independently.
Adding `--dependency` flags during the build phase would enable cross-linking; that is a future
enhancement.

### Output URL structure

Each package's docs are reachable at:

```
https://ebardx.github.io/xesti-packages-docs/documentation/xestimarkov/
https://ebardx.github.io/xesti-packages-docs/documentation/xestitext/
https://ebardx.github.io/xesti-packages-docs/documentation/xestitokens/
https://ebardx.github.io/xesti-packages-docs/documentation/xestitools/
... etc.
```

The synthesized landing page (listing all packages) is at:

```
https://ebardx.github.io/xesti-packages-docs/documentation/
```

---

## GitHub Actions Workflow

The workflow regenerates and publishes the docs automatically. Save as
`.github/workflows/generate-combined-docs.yml`:

```yaml
name: Generate Documentation

on:
  push:
    branches: [main]
  schedule:
    - cron: '0 3 * * *'   # nightly at 03:00 UTC
  workflow_dispatch:       # allows manual trigger from the Actions tab
  repository_dispatch:
    types: [source-updated]

permissions:
  contents: write

jobs:
  docs:
    runs-on: macos-15

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Generate documentation
        run: ./Scripts/generate-combined-docs.sh

      - name: Commit and push docs
        run: |
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add ./docs Package.resolved
          git diff --cached --quiet || git commit -m "docs: regenerate [skip ci]"
          git push
```

### Triggering strategies

**Nightly schedule (simplest):** The `cron` trigger above rebuilds once per night regardless of
what changed. Docs may lag by up to 24 hours after a source package release, which is usually
acceptable.

**Immediate rebuild via `repository_dispatch` (optional enhancement):** Each source package repo
can send a webhook to xesti-packages-docs when it pushes to `main`. Add the following step to
the end of each source package's CI workflow:

```yaml
- name: Trigger xesti-packages-docs rebuild
  uses: peter-evans/repository-dispatch@v3
  with:
    token: ${{ secrets.XESTI_PKG_DOCS_DISPATCH_TOKEN }}
    repository: eBardX/xesti-packages-docs
    event-type: source-updated
```

`XESTI_PKG_DOCS_DISPATCH_TOKEN` is a GitHub fine-grained personal access token (PAT) with
`contents: write` permission on the `xesti-packages-docs` repo, stored as a secret in each
source repo. This is more complex to set up but keeps docs in sync within minutes of each
release.

---

## GitHub Repository Setup

1. Create a new public repo: `https://github.com/eBardX/xesti-packages-docs`
2. Initialize locally:
   ```bash
   cd Tools/xesti-packages-docs
   git init
   git remote add origin https://github.com/eBardX/xesti-packages-docs.git
   ```
3. Run the doc generation command once locally to populate `docs/` before the first push.
4. Add `docs/` to the initial commit along with `Package.swift` and the workflow file.
5. Push to `main`.
6. In the repo's **Settings → Pages**, set the source to **Deploy from a branch**, branch
   `main`, folder `/docs`.

---

## Migration: Retiring Per-Repo Pages

Once the combined site is live and verified:

1. Audit each Xesti repo's README for links to its old Pages URL
   (`https://ebardx.github.io/<RepoName>/documentation/...`) and update them to the new
   combined URLs.
2. Check any release notes, changelogs, or badge links that reference the old URLs.
3. In each source repo's **Settings → Pages**, set the source to **None** to disable the old
   site.

There is no redirect mechanism built into GitHub Pages for project sites, so updating all
inbound links before disabling the old pages is important.

---

## Implementation Checklist

- [x] Create `Tools/xesti-packages-docs/` directory
- [x] Write `Package.swift` (umbrella package, no source targets)
- [x] Write `Scripts/generate-combined-docs.sh` (per-package generation script)
- [x] Write `.github/workflows/generate-combined-docs.yml`
- [x] Run doc generation locally; confirm `docs/` output looks correct
- [ ] Create `eBardX/xesti-packages-docs` repo on GitHub
- [ ] `git init`, add remote, commit, push
- [ ] Enable GitHub Pages in repo settings (source: `main` branch, `/docs` folder)
- [ ] Verify live site at `https://ebardx.github.io/xesti-packages-docs/documentation/`
- [ ] (Optional) Create `XESTI_PKG_DOCS_DISPATCH_TOKEN` PAT and add to each source repo's secrets
- [ ] (Optional) Add `repository_dispatch` step to each source repo's CI workflow
- [ ] Update READMEs and links in all source repos to point to new URLs
- [ ] Disable GitHub Pages on each individual source repo
