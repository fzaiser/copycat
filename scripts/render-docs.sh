#!/usr/bin/env bash
# Renders the images and the PDF that the README links to.
set -eu
cd "$(dirname "$0")/.."
typst compile --root . --format png --ppi 200 docs/example.typ docs/example.png
typst compile --root . docs/gallery.typ docs/gallery.pdf
echo "rendered docs/example.png and docs/gallery.pdf"
