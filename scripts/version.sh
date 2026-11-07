#!/usr/bin/env bash
# Next semantic version from the commits since the last release. Run inside the source clone.
#   version.sh <last released version, e.g. 1.0.3 (empty = none)> <source commit of that release (empty = none)>
# Rules (Conventional Commits): "type!:" or a "BREAKING CHANGE" line -> major; "feat:" -> minor; anything else, including commits that do not
# follow the standard -> patch. No previous release -> BASE_VERSION (default 1.0.0). A last commit that is not in the history any more
# (rewritten) -> patch bump.
set -euo pipefail
last="${1:-}"
sha="${2:-}"
if [ -z "$last" ]; then echo "${BASE_VERSION:-1.0.0}"; exit 0; fi
IFS=. read -r major minor patch <<<"${last#v}"
bump=patch
if [ -n "$sha" ] && git cat-file -e "${sha}^{commit}" 2>/dev/null; then
  range="${sha}..HEAD"
  subjects=$(git log --format=%s "$range")
  if printf '%s\n' "$subjects" | grep -Eq '^[a-zA-Z]+(\([^)]*\))?!:' || git log --format=%B "$range" | grep -Eq '^BREAKING[ -]CHANGE'; then
    bump=major
  elif printf '%s\n' "$subjects" | grep -Eq '^feat(\([^)]*\))?:'; then
    bump=minor
  fi
fi
case "$bump" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  *) patch=$((patch + 1)) ;;
esac
echo "${major}.${minor}.${patch}"
