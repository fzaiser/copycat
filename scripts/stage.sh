#!/usr/bin/env bash
# Assembles the submission copy of the package, i.e. the directory that goes
# into packages/preview/drawstring/<version> of the typst/packages repository.
# It ships typst.toml, LICENSE, README.md and src/ only, and requires every
# other file to be on typst.toml's exclude list, so a new file cannot fall
# between the two. The README's links to unshipped files are pointed at the
# tag v<version> in the repository (raw.githubusercontent.com for images, so
# they render on Typst Universe). The forms the rewrite relies on are checked
# first — plain inline ](target) links to existing files, column-0 ```typst
# fences, exact @preview references — and staging fails rather than guessing.
set -eu
dest=${1:?usage: scripts/stage.sh <directory>}
case $dest in /*) ;; *) dest=$PWD/$dest ;; esac
cd "$(dirname "$0")/.."
if [ -e "$dest" ] && [ -n "$(ls -A "$dest")" ]; then
  echo "$dest exists and is not empty" >&2
  exit 1
fi

name=$(sed -n 's/^name = "\(.*\)"/\1/p' typst.toml)
version=$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)
repo=$(sed -n 's/^repository = "\(.*\)"/\1/p' typst.toml)
errors=0
complain() { echo "$1" >&2; errors=1; }

excluded=$(sed -n 's/^exclude = \[\(.*\)\]$/\1/p' typst.toml | tr -d '"' | tr , ' ')
unlisted=$(find . -name .git -prune -o \( -type f -o -type l \) -print | sed 's|^\./||' | while read -r f; do
  case $f in (typst.toml | LICENSE | README.md | src/*) continue ;; esac
  for e in $excluded; do
    e=${e#/}
    case $f in ("$e" | "$e"/*) continue 2 ;; esac
  done
  echo "$f"
done)
if [ -n "$unlisted" ]; then
  complain "files neither shipped nor on typst.toml's exclude list: ${unlisted//$'\n'/, }"
fi
linked=$(find typst.toml LICENSE README.md src -type l 2>/dev/null || true)
if [ -n "$linked" ]; then
  complain "shipped files must be regular files, found symlinks: ${linked//$'\n'/, }"
fi

links=$(grep -oE '\]\([^)#:[:space:]]+(#[^)[:space:]]*)?\)' README.md | sed 's/^](//; s/)$//' | sort -u)
for target in $links; do
  [ -e "${target%%#*}" ] || complain "README links to missing path: $target"
done

canonical=$(grep -c '^```typst$' README.md || true)
loose=$(grep -ciE '^ {0,3}(`{3,}|~{3,})[[:blank:]]*typst' README.md || true)
if [ "$loose" -ne "$canonical" ]; then
  complain "README has $loose typst fences but only $canonical in the canonical form the tests compile (\`\`\`typst at column 0)"
fi

# Every token starting @preview/ must be this package at its manifest version,
# or cetz at the one version src/ pins, so a typo'd name, a missing colon, or
# a short or suffixed version fails instead of slipping past. A token may
# close a sentence, so one trailing punctuation mark is stripped.
until_delimiter='[^][:space:]"'\''`)]*'
cetz=$(grep -rhoE "@preview/cetz:$until_delimiter" src | sort -u)
case $cetz in
  '' | *$'\n'*) complain "src/ must import exactly one cetz version, found: ${cetz:-none}" ;;
esac
wrong=$(grep -hoE "@preview/$until_delimiter" README.md docs/*.typ docs/figures/*.typ | sed 's/[.,;:]$//' | sort -u \
  | grep -vxF -e "@preview/$name:$version" -e "$cetz" || true)
if [ -n "$wrong" ]; then
  complain "README and docs must reference @preview/$name:$version or $cetz only, found: ${wrong//$'\n'/, }"
fi
grep -qF "@preview/$name:$version" README.md || complain "README never references @preview/$name:$version"

[ "$errors" -eq 0 ] || exit 1

mkdir -p "$dest"
cp -R typst.toml LICENSE src "$dest/"
rewrite=$(mktemp)
for target in $links; do
  path=${target%%#*}
  [ -e "$dest/$path" ] && continue
  case $path in
    *.svg | *.png) url="${repo/github.com/raw.githubusercontent.com}/v$version/$path" ;;
    *) url="$repo/blob/v$version/$path" ;;
  esac
  case $target in *#*) url="$url#${target#*#}" ;; esac
  printf 's,](%s),](%s),g\n' "$target" "$url" >> "$rewrite"
done
sed -f "$rewrite" README.md > "$dest/README.md"
rm -f "$rewrite"
echo "staged $(find "$dest" -type f | wc -l | tr -d ' ') files in $dest"
