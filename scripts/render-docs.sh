#!/usr/bin/env bash
# Renders the images and the PDF that the README links to. The docs import
# copycat as a package, so the checkout is linked into a package path first.
set -eu
cd "$(dirname "$0")/.."
version=$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)
pkg=tests/out/packages
mkdir -p "$pkg/preview/copycat"
ln -sfn "$PWD" "$pkg/preview/copycat/$version"
typst compile --root . --package-path "$pkg" --format svg docs/example.typ docs/example-light.svg
typst compile --root . --package-path "$pkg" --format svg --input theme=dark docs/example.typ docs/example-dark.svg
typst compile --root . --package-path "$pkg" docs/gallery.typ docs/gallery.pdf
echo "rendered docs/example-light.svg, docs/example-dark.svg and docs/gallery.pdf"
