# Publishing copycat to Typst Universe

Packages live in the [typst/packages](https://github.com/typst/packages) repository under `packages/preview/<name>/<version>/` and are imported as `@preview/<name>:<version>`.
The authoritative rules are in that repository's [docs/](https://github.com/typst/packages/tree/main/docs); this file records how they apply to copycat, so that a release does not have to re-derive them.
[CONTRIBUTING.md](CONTRIBUTING.md) covers the development workflow.

## Pre-submission checklist

1. Set `version` in `typst.toml` and in every `@preview/copycat:` import in `README.md` and `docs/`; `scripts/test.sh` fails on a mismatch.
2. Run `scripts/render-docs.sh` and then `scripts/test.sh`, with `typst-package-check` and `typos` installed so that nothing is skipped.
3. Confirm `authors` and `repository` in `typst.toml` and the holder and year in `LICENSE`.
4. Commit, tag the commit and push both: `git tag -a v<version> -m "copycat <version>"`.

## Submitting

A sparse checkout of a fork keeps the registry clone small:

```sh
git clone --depth 1 --no-checkout --filter="tree:0" git@github.com:<you>/packages
cd packages && git sparse-checkout init
git sparse-checkout set packages/preview/copycat
git remote add upstream git@github.com:typst/packages
git config remote.upstream.partialclonefilter tree:0
git checkout main
```

Then assemble the submission into a new versioned directory (note the doubled `packages/`), commit it and open a pull request against `typst/packages`:

```sh
<copycat checkout>/scripts/stage.sh packages/preview/copycat/<version>
```

Copy files only, never a `.git` directory; submodules are not accepted.
Once the pull request is merged and CI has run, the version can be imported right away and shows up on Universe within about half an hour.

## Releasing a new version

Every change to a published package is a new version in a new directory; a directory that has been published is never edited again.
Run the checklist above and submit as for the first version.
Updates are expected to come from the author who submitted the previous version; anyone else is asked to get the previous author's consent first.

## Gotchas

- `typst-package-check` compiles the package with its own bundled Typst and resolves cetz from the local package cache only; it never downloads a package, online or not. `scripts/test.sh` therefore compiles the tests before it lints, which is what fills the cache on a fresh CI runner.
- Run the checker on the staged copy, not in the repository root, where it reports every gitignored file, including all of `.git/`, as `files/ignored`.
- The README images are transparent SVGs in a light and a dark variant, selected by `<picture>`; `scripts/render-docs.sh` regenerates both.
