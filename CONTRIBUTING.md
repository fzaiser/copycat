# Contributing to copycat

## Development

The library lives in [src/](src/), behind the entrypoint [src/lib.typ](src/lib.typ), which re-exports exactly the documented names.
[docs/design.md](docs/design.md) explains how the layout works; read it before changing `src/core.typ`.

`scripts/test.sh` runs the whole test suite and needs nothing but `typst`:

- `tests/*.typ` and `docs/*.typ` must compile without warnings, and `docs/example.typ` also in its dark variant;
- every file in `tests/fail/` must fail with the error named on its first line;
- the README's quick start must compile against the package as a user would import it;
- every `@preview/copycat:<version>` import in the README and in `docs/` must name the version in `typst.toml`;
- the submission copy assembled by `scripts/stage.sh` must pass `typst-package-check`, and the sources `typos`.

The last two checks are skipped, visibly, when the tools are not installed, and `scripts/test.sh --offline` skips the lints that need network access, such as the check that `repository` is reachable.
CI runs all of them, on the compiler floor from `typst.toml` and on the current Typst release.

```sh
cargo install --git https://github.com/typst/package-check --locked
brew install typos-cli   # or: cargo install typos-cli
```

The files in `docs/` import `@preview/copycat:<version>` rather than `../src/lib.typ`, so that they can be copied as they are.
`scripts/test.sh` compiles them, and the README's quick start, against the submission copy that `scripts/stage.sh` assembles in `tests/out/staged`, so anything missing from that copy fails there.
`scripts/render-docs.sh` instead links the checkout itself into `tests/out/packages`, which is also the path to pass when working on a document in `docs/` interactively:

```sh
typst watch --root . --package-path tests/out/packages docs/gallery.typ
```

`scripts/render-docs.sh` regenerates the SVGs and the PDF that the README links to.
Run it after a change that affects the rendered output and commit the result.

To use a checkout from other documents on your machine, `scripts/install-local.sh` links it into Typst's local package directory as `@local/copycat:<version>`.

## Releasing

[PUBLISHING.md](PUBLISHING.md) records the registry's rules as they apply to copycat, the pre-submission checklist, and how to submit a version.
