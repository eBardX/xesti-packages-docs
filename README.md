# xesti-packages-docs

Combined DocC documentation site for all Xesti packages.

## <a name="overview">Overview</a>

The repository aggregates the API reference documentation for the full Xesti
family of Swift packages into a single, cross-linked [DocC][docc] site published
via GitHub Pages.

A nightly CI job checks whether any package's `main` branch has changed since
the last build. If so, it rebuilds the combined archive, transforms it for
static hosting, and force-pushes the result to the `docc-publish` branch, from
which GitHub Pages serves the site. If nothing has changed upstream, the job
exits early without rebuilding or committing anything. The `main` branch of this
repository contains only source and configuration — no generated output.

Packages covered:

- [XestiMarkov][xestimarkov] — Markov chain tools
- [XestiNetwork][xestinetwork] — A simple network abstraction layer
- [XestiNumbers][xestinumbers] — A Swift number tower
- [XestiSexp][xestisexp] — An S-expression encoder and decoder
- [XestiText][xestitext] — Text formatting tools
- [XestiTokens][xestitokens] — A rules-based lexical tokenizer
- [XestiTools][xestitools] — Tools to ease writing Swift code
- [XestiXML][xestixml] — XML tools

## <a name="reference_documentation">Reference Documentation</a>

Full [reference documentation][refdoc] is available courtesy of [DocC][docc].

## <a name="credits">Credits</a>

John Gary Pusey (ebardx@gmail.com)

## <a name="license">License</a>

xesti-packages-docs is available under [the MIT license][license].

[docc]:         https://www.swift.org/documentation/docc/
[license]:      https://github.com/eBardX/xesti-packages-docs/blob/main/LICENSE.md
[refdoc]:       https://eBardX.github.io/xesti-packages-docs/documentation/
[xestimarkov]:  https://github.com/eBardX/XestiMarkov
[xestinetwork]: https://github.com/eBardX/XestiNetwork
[xestinumbers]: https://github.com/eBardX/XestiNumbers
[xestisexp]:    https://github.com/eBardX/XestiSexp
[xestitext]:    https://github.com/eBardX/XestiText
[xestitokens]:  https://github.com/eBardX/XestiTokens
[xestitools]:   https://github.com/eBardX/XestiTools
[xestixml]:     https://github.com/eBardX/XestiXML
