#!/usr/bin/env bash
# Assembles the submission copy of the package, i.e. the directory that goes into
# packages/preview/copycat/<version> of the typst/packages repository. It holds
# the shipped files and docs/, which the README links to and typst.toml excludes
# from the downloaded bundle. Development files (tests, scripts, CI) stay behind.
set -eu
dest=${1:?usage: scripts/stage.sh <directory>}
case $dest in /*) ;; *) dest=$PWD/$dest ;; esac
cd "$(dirname "$0")/.."
if [ -e "$dest" ] && [ -n "$(ls -A "$dest")" ]; then
  echo "$dest exists and is not empty" >&2
  exit 1
fi
mkdir -p "$dest"
cp -R typst.toml LICENSE README.md src docs "$dest/"
echo "staged $(find "$dest" -type f | wc -l | tr -d ' ') files in $dest"
