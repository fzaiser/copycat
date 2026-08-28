#!/usr/bin/env bash
# Assembles the submission copy of the package, i.e. the directory that goes
# into packages/preview/drawstring/<version> of the typst/packages repository. It
# holds the shipped files only; the docs and the other development files stay
# behind, and the README's links to them are pointed at the tag v<version> in
# the repository, so that they work on Typst Universe.
set -eu
dest=${1:?usage: scripts/stage.sh <directory>}
case $dest in /*) ;; *) dest=$PWD/$dest ;; esac
cd "$(dirname "$0")/.."
if [ -e "$dest" ] && [ -n "$(ls -A "$dest")" ]; then
  echo "$dest exists and is not empty" >&2
  exit 1
fi
version=$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)
repo=$(sed -n 's/^repository = "\(.*\)"/\1/p' typst.toml)
mkdir -p "$dest"
cp -R typst.toml LICENSE src "$dest/"
rewrite=$(mktemp)
for path in $(grep -oE '\]\([^)#:[:space:]]+\)' README.md | sed 's/^](//; s/)$//' | sort -u); do
  [ -e "$dest/$path" ] && continue
  case $path in
    *.svg | *.png) url="${repo/github.com/raw.githubusercontent.com}/v$version/$path" ;;
    *) url="$repo/blob/v$version/$path" ;;
  esac
  printf 's,](%s),](%s),g\n' "$path" "$url" >> "$rewrite"
done
sed -f "$rewrite" README.md > "$dest/README.md"
rm -f "$rewrite"
echo "staged $(find "$dest" -type f | wc -l | tr -d ' ') files in $dest"
