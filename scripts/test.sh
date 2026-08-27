#!/usr/bin/env bash
# Runs the test suite; CONTRIBUTING.md lists what it checks. Only typst is
# required; typst-package-check and typos are used when installed. `--offline`
# skips the lints that need network access.
set -u
cd "$(dirname "$0")/.."
offline=
for arg in "$@"; do
  case $arg in
    --offline) offline=--offline ;;
    *) echo "usage: scripts/test.sh [--offline]" >&2; exit 2 ;;
  esac
done
out=tests/out
mkdir -p "$out"
pass=0
fail=0
skip=0

ok() { pass=$((pass + 1)); echo "ok    $1"; }
bad() {
  fail=$((fail + 1))
  echo "FAIL  $1"
  if [ -n "${2:-}" ]; then printf '%s\n' "$2" | sed 's/^/      /'; fi
}
skipped() { skip=$((skip + 1)); echo "skip  $1"; }

# A compile passes only if typst succeeds without printing a warning.
compile() { # compile <label> <output name> <file> [typst options...]
  local label=$1 name=$2 file=$3 err
  shift 3
  if err=$(typst compile --root . "$@" "$file" "$out/$name.pdf" 2>&1) && ! printf '%s' "$err" | grep -qi 'warning'; then
    ok "$label"
  else
    bad "$label" "$err"
  fi
}

version=$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)

for f in tests/*.typ; do compile "$f" "$(basename "${f%.typ}")" "$f"; done

# The docs and the README import copycat as a package. They are compiled against
# the submission copy, so that anything stage.sh leaves out fails here.
staged=$out/staged
rm -rf "$staged"
if err=$(scripts/stage.sh "$staged/preview/copycat/$version" 2>&1); then ok "scripts/stage.sh"; else bad "scripts/stage.sh" "$err"; fi
for f in docs/*.typ; do compile "$f" "$(basename "${f%.typ}")" "$f" --package-path "$staged"; done
for f in docs/figures/*.typ; do
  name=$(basename "${f%.typ}")
  [ "$name" = setup ] && continue
  compile "$f" "figure-$name" "$f" --package-path "$staged"
done

for f in tests/fail/*.typ; do
  want=$(sed -n '1s#^// error: ##p' "$f")
  if [ -z "$want" ]; then bad "$f" "the first line must be '// error: <expected text>'"; continue; fi
  if err=$(typst compile --root . "$f" "$out/fail-$(basename "${f%.typ}").pdf" 2>&1); then
    bad "$f" "compiled, but should have failed with: $want"
  elif printf '%s' "$err" | grep -qF -- "$want"; then
    ok "$f"
  else
    bad "$f" "expected an error containing: $want"$'\n'"$err"
  fi
done

awk '/^```typst/ { if (++n == 1) { on = 1; next } } /^```$/ { on = 0 } on' README.md > "$out/readme-quickstart.typ"
compile "README quick start" readme-quickstart "$out/readme-quickstart.typ" --package-path "$staged"

imports=$(grep -ohE '@preview/copycat:[0-9]+\.[0-9]+\.[0-9]+' README.md docs/*.typ docs/figures/*.typ | sort -u)
if [ "$imports" = "@preview/copycat:$version" ]; then
  ok "README and docs import copycat $version"
else
  bad "imports" "README.md and docs/ must import copycat $version, found:"$'\n'"$imports"
fi

# Relative links in the README must exist in the checkout; stage.sh turns the
# ones that are not part of the package into repository links.
missing=$(grep -oE '\]\([^)#:[:space:]]+\)' README.md | sed 's/^](//; s/)$//' | sort -u | while read -r path; do
  [ -e "$path" ] || echo "$path"
done)
if [ -z "$missing" ]; then ok "README links resolve"; else bad "README links" "not found:"$'\n'"$missing"; fi

# The lint runs after the compiles above: typst-package-check resolves cetz
# from the package cache only, which they fill on a fresh machine.
if command -v typst-package-check >/dev/null; then
  if err=$(typst-package-check check $offline "$staged/preview/copycat/$version" 2>&1); then ok "typst-package-check"; else bad "typst-package-check" "$err"; fi
else
  skipped "typst-package-check is not installed (cargo install --git https://github.com/typst/package-check --locked)"
fi

if command -v typos >/dev/null; then
  if err=$(typos 2>&1); then ok "typos"; else bad "typos" "$err"; fi
else
  skipped "typos is not installed (brew install typos-cli)"
fi

echo "$pass passed, $fail failed, $skip skipped"
[ "$fail" -eq 0 ]
