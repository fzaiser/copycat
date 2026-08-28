#!/usr/bin/env bash
# Renders the README figures and the gallery PDF. The docs import drawstring as a
# package, so the checkout is linked into a package path first.
#
# Every page of a docs/figures/*.typ file is one figure, named by its
# `fig("name", ...)` call (see docs/figures/setup.typ), and is written to
# docs/images/<name>.svg. With `--check`, everything is rendered under
# tests/out instead and compared with the committed files.
set -eu
cd "$(dirname "$0")/.."
check=
for arg in "$@"; do
  case $arg in
    --check) check=1 ;;
    *) echo "usage: scripts/render-docs.sh [--check]" >&2; exit 2 ;;
  esac
done
version=$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)
pkg=tests/out/packages
mkdir -p "$pkg/preview/drawstring"
ln -sfn "$PWD" "$pkg/preview/drawstring/$version"
# Only typst's bundled fonts are used, and the PDF gets a fixed creation date,
# so that the output is the same on every machine and every run.
opts=(--root . --package-path "$pkg" --ignore-system-fonts --creation-timestamp 0)

# Shown through <img>, as on GitHub and Typst Universe, an SVG still applies
# its own media queries: this block turns the black ink white in dark mode.
css='<style>@media (prefers-color-scheme: dark) { [fill="#000000"] { fill: #fff } [stroke="#000000"] { stroke: #fff } }</style>'

out=docs
if [ -n "$check" ]; then out=tests/out/docs; fi
pages=tests/out/figures
rm -rf "$pages" "$out/images"
mkdir -p "$pages" "$out/images"
for f in docs/figures/*.typ; do
  stem=$(basename "${f%.typ}")
  [ "$stem" = setup ] && continue
  typst compile "${opts[@]}" --format svg "$f" "$pages/$stem-{p}.svg"
  p=0
  for name in $(grep -o 'fig("[^"]*"' "$f" | sed 's/^fig("//; s/"$//'); do
    p=$((p + 1))
    page=$pages/$stem-$p.svg
    [ -f "$page" ] || { echo "$f: no page $p for figure $name" >&2; exit 1; }
    [ ! -e "$out/images/$name.svg" ] || { echo "$f: figure $name is defined twice" >&2; exit 1; }
    grep -q '#000000' "$page" || { echo "$page: no black ink to restyle; has typst's SVG output changed?" >&2; exit 1; }
    sed "s|<svg\([^>]*\)>|<svg\1>$css|" "$page" > "$out/images/$name.svg"
  done
  [ ! -f "$pages/$stem-$((p + 1)).svg" ] || { echo "$f: more pages than figures" >&2; exit 1; }
done
typst compile "${opts[@]}" docs/gallery.typ "$out/gallery.pdf"
# The output differs between typst releases, so the tests compare it only
# under the release that rendered it.
typst --version | sed 's/^typst \([0-9.]*\).*/\1/' > "$out/typst-version"

if [ -n "$check" ]; then
  stale=$({
    diff -rq docs/images "$out/images"
    cmp -s docs/gallery.pdf "$out/gallery.pdf" || echo "docs/gallery.pdf differs"
    cmp -s docs/typst-version "$out/typst-version" || echo "docs/typst-version differs"
  } 2>&1 || true)
  if [ -z "$stale" ]; then
    echo "docs/images, docs/gallery.pdf and docs/typst-version are up to date"
  else
    printf '%s\n' "$stale" >&2
    echo "the rendered docs are out of date: run scripts/render-docs.sh" >&2
    exit 1
  fi
  exit 0
fi
echo "rendered docs/images/*.svg and docs/gallery.pdf with typst $(cat docs/typst-version)"
