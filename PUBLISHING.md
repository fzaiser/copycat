# Publishing copycat to Typst Universe

Packages live in the [typst/packages](https://github.com/typst/packages) repository under `packages/preview/<name>/<version>/` and are imported as `@preview/<name>:<version>`.
The authoritative rules are in that repository's [docs/](https://github.com/typst/packages/tree/main/docs); this file is what they mean for copycat, so that a release does not have to re-derive them.

## Checklist

1. Set `version` in `typst.toml` and in every `@preview/copycat:` import in `README.md` and under `docs/`.
   `scripts/test.sh` fails on a mismatch.
2. Run `scripts/render-docs.sh`, then `scripts/test.sh` with `typst-package-check` and `typos` installed, so that nothing is skipped.
3. Check `authors` and `repository` in `typst.toml`, and the holder and year in `LICENSE`.
4. Commit, tag and push: `git tag -a v<version> -m "copycat <version>"`.
   The staged README links to this tag, so it has to be on GitHub before the package goes live.

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

`scripts/stage.sh` copies the shipped files only.
The README's links to anything else, such as the figures and the gallery, are rewritten to point at the tag `v<version>` in the repository, so that they work on Typst Universe.
Copy files only, never a `.git` directory; submodules are not accepted.
Once the pull request is merged and CI has run, the version can be imported right away and shows up on Universe within about half an hour.

## New versions

Every change to a published package is a new version in a new directory; a directory that has been published is never edited again.
Run the checklist and submit as for the first version.
Updates are expected to come from the author who submitted the previous version; anyone else should get that author's consent first.

## Gotchas

- `typst-package-check` compiles the package with its own bundled Typst and resolves CeTZ from the local package cache only; it never downloads a package.
  `scripts/test.sh` therefore compiles the tests before it lints, which fills the cache on a fresh CI runner.
- Run the checker on the staged copy, not in the repository root, where it reports every gitignored file, including all of `.git/`, as `files/ignored`.
- The checker rejects README links to files that are not in the submission and warns about GitHub links to the default branch, which is why `scripts/stage.sh` rewrites them to links to a tag.
