#!/usr/bin/env bash
# Renders the README figures and the gallery PDF. The docs import copycat as a
# package, so the checkout is linked into a package path first.
#
# Every page of a docs/figures/*.typ file is one figure, named by its
# `fig("name", ...)` call (see docs/figures/setup.typ), and is written to
# docs/images/<name>.svg.
set -eu
cd "$(dirname "$0")/.."
version=$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)
pkg=tests/out/packages
mkdir -p "$pkg/preview/copycat"
ln -sfn "$PWD" "$pkg/preview/copycat/$version"
opts=(--root . --package-path "$pkg")

# Shown through <img>, as on GitHub and Typst Universe, an SVG still applies
# its own media queries: this block turns the black ink white in dark mode.
css='<style>@media (prefers-color-scheme: dark) { [fill="#000000"] { fill: #fff } [stroke="#000000"] { stroke: #fff } }</style>'

pages=tests/out/figures
rm -rf "$pages" docs/images
mkdir -p "$pages" docs/images
for f in docs/figures/*.typ; do
  stem=$(basename "${f%.typ}")
  [ "$stem" = setup ] && continue
  typst compile "${opts[@]}" --format svg "$f" "$pages/$stem-{p}.svg"
  p=0
  for name in $(grep -o 'fig("[^"]*"' "$f" | sed 's/^fig("//; s/"$//'); do
    p=$((p + 1))
    page=$pages/$stem-$p.svg
    [ -f "$page" ] || { echo "$f: no page $p for figure $name" >&2; exit 1; }
    [ ! -e "docs/images/$name.svg" ] || { echo "$f: figure $name is defined twice" >&2; exit 1; }
    grep -q '#000000' "$page" || { echo "$page: no black ink to restyle; has typst's SVG output changed?" >&2; exit 1; }
    sed "s|<svg\([^>]*\)>|<svg\1>$css|" "$page" > "docs/images/$name.svg"
  done
  [ ! -f "$pages/$stem-$((p + 1)).svg" ] || { echo "$f: more pages than figures" >&2; exit 1; }
done
typst compile "${opts[@]}" docs/gallery.typ docs/gallery.pdf
echo "rendered docs/images/*.svg and docs/gallery.pdf"
