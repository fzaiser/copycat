# Contributing to drawstring

## Where things are

| Path | Contents |
|---|---|
| `src/` | the library; `lib.typ` re-exports exactly the documented names |
| `docs/gallery.typ` | one document that shows everything; `gallery.pdf` is its output |
| `docs/figures/` | the sources of the README figures |
| `docs/images/` | the README figures, rendered by `scripts/render-docs.sh` |
| `tests/` | the test suite; `tests/fail/` holds documents that must fail to compile |
| `scripts/` | the test, rendering and packaging scripts |
| `ARCHITECTURE.md` | how the layout works; read it before changing `src/core.typ` |
| `PUBLISHING.md` | how a version is released to Typst Universe |

## Running the tests

`scripts/test.sh` needs nothing but `typst`.
It checks that

- `tests/*.typ`, `docs/*.typ` and `docs/figures/*.typ` compile without warnings;
- every file in `tests/fail/` fails with the error named on its first line;
- the README's first code block, the quick start, compiles against the package as a user would import it;
- every `@preview/drawstring:<version>` import in the README and under `docs/` names the version in `typst.toml`;
- every relative link in the README points at an existing file;
- the figures in `docs/images/` match their sources, under the Typst release that rendered them;
- the submission copy assembled by `scripts/stage.sh` passes `typst-package-check`, and the sources pass `typos`.

The last two checks are skipped, with a notice, when the tools are not installed:

```sh
cargo install --git https://github.com/typst/package-check --locked
brew install typos-cli   # or: cargo install typos-cli
```

`scripts/test.sh --offline` skips the lints that need network access, such as the check that `repository` is reachable.
CI runs everything on the compiler floor from `typst.toml` and on the current Typst release.

## Working on the docs

The files under `docs/` import `@preview/drawstring:<version>` rather than `../src/lib.typ`, so that they work unchanged when copied into a document.
The tests compile them against the submission copy that `scripts/stage.sh` assembles in `tests/out/staged`, so anything missing from that copy fails there.

To work on a document interactively, link the checkout into a package path and pass it to `typst`.
`scripts/render-docs.sh` sets up `tests/out/packages` for this:

```sh
typst watch --root . --package-path tests/out/packages docs/gallery.typ
```

`scripts/render-docs.sh` regenerates the README figures and `docs/gallery.pdf`.
Each figure is one page of a file in `docs/figures/`, wrapped in `fig("name", ...)` from `docs/figures/setup.typ`, and is written to `docs/images/name.svg`.
The script also adds a style block to every SVG that turns black ink white when the reader's colour scheme is dark, which is why the figures leave boxes and triangles unfilled.
Run the script after any change that affects the rendered output, and commit the result; under the Typst release that rendered them, the tests fail when the figures are out of date.

## Using a checkout from other documents

`scripts/install-local.sh` links the checkout into Typst's local package directory as `@local/drawstring:<version>`, so that other documents on the machine see edits immediately.

## Releasing

See [PUBLISHING.md](PUBLISHING.md).
