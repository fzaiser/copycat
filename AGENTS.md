# Instructions for AI agents

Read [CONTRIBUTING.md](CONTRIBUTING.md) first; it covers the repo layout, the test suite, and the docs rendering workflow.
Read [ARCHITECTURE.md](ARCHITECTURE.md) before changing `src/core.typ`, and [PUBLISHING.md](PUBLISHING.md) before touching anything release-related.

## Documentation style

Documentation is written for human readers, who grok a picture plus a code snippet much faster than a paragraph.

- Show features as rendered figures paired with the code that produced them; prefer lists, tables and subsections over prose.
- The code belongs in the Markdown next to the figure — copyable, with nested calls indented — never inside the rendered image.
- Order sections by what a library user needs first, e.g. styling before custom primitives.
- README examples must make sense without a probability background: the running example is a camera whose photo is kept and described in text, not `Uniform`/`Bernoulli`.
- Contributor material stays in the top-level files (`ARCHITECTURE.md`, `CONTRIBUTING.md`, `PUBLISHING.md`); the README links to them with relative paths, which `scripts/stage.py` rewrites to tag URLs for Typst Universe.
