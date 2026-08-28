#!/usr/bin/env bash
# Renders the README figures and the gallery PDF. The docs import drawstring as a
# package, so the checkout is linked into a package path first.
#
# Every page of a docs/figures/*.typ file is one figure, named by its
# `fig("name", ...)` call (see docs/figures/setup.typ), and is written to
# docs/images/<name>.svg. With `--check`, the figures are rendered to
# tests/out/images instead and compared with docs/images.
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
# Only typst's bundled fonts are used, so that the figures come out the same
# on every machine.
opts=(--root . --package-path "$pkg" --ignore-system-fonts)

# Shown through <img>, as on GitHub and Typst Universe, an SVG still applies
# its own media queries: this block turns the black ink white in dark mode.
css='<style>@media (prefers-color-scheme: dark) { [fill="#000000"] { fill: #fff } [stroke="#000000"] { stroke: #fff } }</style>'

images=docs/images
if [ -n "$check" ]; then images=tests/out/images; fi
pages=tests/out/figures
rm -rf "$pages" "$images"
mkdir -p "$pages" "$images"
for f in docs/figures/*.typ; do
  stem=$(basename "${f%.typ}")
  [ "$stem" = setup ] && continue
  typst compile "${opts[@]}" --format svg "$f" "$pages/$stem-{p}.svg"
  p=0
  for name in $(grep -o 'fig("[^"]*"' "$f" | sed 's/^fig("//; s/"$//'); do
    p=$((p + 1))
    page=$pages/$stem-$p.svg
    [ -f "$page" ] || { echo "$f: no page $p for figure $name" >&2; exit 1; }
    [ ! -e "$images/$name.svg" ] || { echo "$f: figure $name is defined twice" >&2; exit 1; }
    grep -q '#000000' "$page" || { echo "$page: no black ink to restyle; has typst's SVG output changed?" >&2; exit 1; }
    sed "s|<svg\([^>]*\)>|<svg\1>$css|" "$page" > "$images/$name.svg"
  done
  [ ! -f "$pages/$stem-$((p + 1)).svg" ] || { echo "$f: more pages than figures" >&2; exit 1; }
done
# The SVG output can change between typst releases, so the tests compare the
# figures only under the release that rendered them.
typst --version | sed 's/^typst \([0-9.]*\).*/\1/' > "$images/typst-version"

if [ -n "$check" ]; then
  if diff -r docs/images "$images" >/dev/null; then
    echo "docs/images matches docs/figures"
  else
    diff -rq docs/images "$images" >&2 || true
    echo "docs/images is out of date: run scripts/render-docs.sh" >&2
    exit 1
  fi
  exit 0
fi
typst compile "${opts[@]}" docs/gallery.typ docs/gallery.pdf
echo "rendered docs/images/*.svg and docs/gallery.pdf"
