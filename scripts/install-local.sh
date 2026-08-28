#!/usr/bin/env bash
# Links this checkout into Typst's local package directory, so that documents
# on this machine can `#import "@local/drawstring:<version>"` and see edits
# immediately. Re-run after changing the version in typst.toml.
set -eu
cd "$(dirname "$0")/.."
version=$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)
case "$(uname -s)" in
  Darwin) base="$HOME/Library/Application Support/typst/packages" ;;
  Linux) base="${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages" ;;
  *) echo "unsupported platform: $(uname -s)" >&2; exit 1 ;;
esac
dir="$base/local/drawstring"
target="$dir/$version"
if [ -e "$target" ] && [ ! -L "$target" ]; then
  echo "$target exists and is not a symlink; remove it first" >&2
  exit 1
fi
mkdir -p "$dir"
ln -sfn "$PWD" "$target"
echo "linked $target -> $PWD"
echo "use it with: #import \"@local/drawstring:$version\": *"
