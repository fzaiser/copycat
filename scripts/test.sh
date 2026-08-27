#!/usr/bin/env bash
# Runs the test suite: every file in tests/ and the gallery must compile, every
# file in tests/fail/ must fail with the error named on its first line, and the
# README's imports must name the version in typst.toml.
set -u
cd "$(dirname "$0")/.."
out=tests/out
mkdir -p "$out"
pass=0
fail=0

ok() { pass=$((pass + 1)); echo "ok    $1"; }
bad() {
  fail=$((fail + 1))
  echo "FAIL  $1"
  if [ -n "${2:-}" ]; then printf '%s\n' "$2" | sed 's/^/      /'; fi
}

for f in tests/*.typ docs/gallery.typ docs/example.typ; do
  if err=$(typst compile --root . "$f" "$out/$(basename "${f%.typ}").pdf" 2>&1); then ok "$f"; else bad "$f" "$err"; fi
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

version=$(sed -n 's/^version = "\(.*\)"/\1/p' typst.toml)
imports=$(grep -oE '@preview/copycat:[0-9]+\.[0-9]+\.[0-9]+' README.md | sort -u)
if [ -z "$imports" ]; then
  bad "README" "no @preview/copycat import found"
elif [ "$imports" = "@preview/copycat:$version" ]; then
  ok "README imports copycat $version"
else
  bad "README" "imports do not all match version $version:"$'\n'"$imports"
fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
