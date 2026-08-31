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

# The docs and the README import drawstring as a package. They are compiled against
# the submission copy, so that anything stage.sh leaves out fails here. Staging also
# validates the README (links, fences, @preview references), so a violation fails here.
staged=$out/staged
rm -rf "$staged"
if err=$(scripts/stage.sh "$staged/preview/drawstring/$version" 2>&1); then ok "scripts/stage.sh"; else bad "scripts/stage.sh" "$err"; fi
for f in docs/*.typ; do compile "$f" "$(basename "${f%.typ}")" "$f" --package-path "$staged"; done
for f in docs/figures/*.typ; do
  name=$(basename "${f%.typ}")
  [ "$name" = setup ] && continue
  compile "$f" "figure-$name" "$f" --package-path "$staged"
done

# The committed figures and gallery must match their sources. Typst's output
# differs between releases, so only the release that rendered them can tell;
# CI installs that release for this check.
rendered=$(cat docs/typst-version 2>/dev/null || true)
installed=$(typst --version | sed 's/^typst \([0-9.]*\).*/\1/')
if ! printf '%s\n' "$rendered" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  bad "docs/typst-version" "expected the typst release that rendered the docs, found '$rendered'; run scripts/render-docs.sh"
elif [ "$installed" = "$rendered" ]; then
  if err=$(scripts/render-docs.sh --check 2>&1); then ok "rendered docs are up to date"; else bad "rendered docs" "$err"; fi
else
  skipped "the docs were rendered with typst $rendered, not $installed"
fi

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

# Every README ```typst example, concatenated in order (later ones build on
# earlier ones), must compile against the submission copy. An example with no
# `#` line is a bare expression shown for its shape; it is bound with a #let
# so it is still evaluated rather than typeset as text.
if awk '
  /^```typst$/ { if (on) exit 1; on = 1; bare = 1; n++; m = 0; next }
  /^```$/ && on { on = 0
    if (n > 1) print ""
    if (bare) print "#let readme-example-" n " = ("
    for (i = 1; i <= m; i++) print line[i]
    if (bare) print ")" }
  on { line[++m] = $0; if ($0 ~ /^#/) bare = 0 }
  END { if (on || n == 0) exit 1 }
' README.md > "$out/readme-examples.typ"; then
  compile "README examples" readme-examples "$out/readme-examples.typ" --package-path "$staged"
else
  bad "README examples" 'README.md must have ```typst fences, each closed by ``` at column 0'
fi

# The lint runs after the compiles above: typst-package-check resolves cetz
# from the package cache only, which they fill on a fresh machine.
if command -v typst-package-check >/dev/null; then
  if err=$(typst-package-check check $offline "$staged/preview/drawstring/$version" 2>&1); then ok "typst-package-check"; else bad "typst-package-check" "$err"; fi
else
  skipped "typst-package-check is not installed (cargo install --git https://github.com/typst/package-check --rev 50eb19311fde --locked)"
fi

if command -v typos >/dev/null; then
  if err=$(typos 2>&1); then ok "typos"; else bad "typos" "$err"; fi
else
  skipped "typos is not installed (brew install typos-cli)"
fi

echo "$pass passed, $fail failed, $skip skipped"
[ "$fail" -eq 0 ]
