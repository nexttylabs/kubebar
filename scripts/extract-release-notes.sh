#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHANGELOG_FILE="${CHANGELOG_FILE:-$ROOT_DIR/CHANGELOG.md}"
VERSION="${1:-}"

usage() {
  echo "Usage: $0 <version>" >&2
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

[ -n "$VERSION" ] || { usage; exit 2; }
[[ "$VERSION" =~ ^[0-9]+[.][0-9]+[.][0-9]+([-+][0-9A-Za-z.-]+)?$ ]] || fail "Version must look like X.Y.Z"
[ -f "$CHANGELOG_FILE" ] || fail "Changelog not found: $CHANGELOG_FILE"

match_count="$(
  awk -v version="$VERSION" '
    BEGIN {
      target = "## [" version "] - "
    }
    index($0, target) == 1 && $0 ~ /^## \[[^]]+\] - [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ {
      count++
    }
    END {
      print count + 0
    }
  ' "$CHANGELOG_FILE"
)"
[ "$match_count" -eq 1 ] || fail "Expected exactly one finalized changelog section for $VERSION, found $match_count"

notes="$(
  awk -v version="$VERSION" '
    BEGIN {
      target = "## [" version "] - "
    }
    /^## / {
      if (found) {
        exit
      }
      if (index($0, target) == 1 && $0 ~ /^## \[[^]]+\] - [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) {
        found = 1
        next
      }
    }
    found {
      print
    }
  ' "$CHANGELOG_FILE"
)"

if [ -z "$(printf '%s\n' "$notes" | sed '/^[[:space:]]*$/d')" ]; then
  fail "Changelog section for $VERSION is empty"
fi

if ! printf '%s\n' "$notes" | grep -q '^- '; then
  fail "Changelog section for $VERSION has no bullet entries"
fi

printf '%s\n' "$notes"
