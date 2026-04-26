#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHANGELOG_FILE="${CHANGELOG_FILE:-$ROOT_DIR/CHANGELOG.md}"
FRAGMENTS_DIR="${CHANGELOG_FRAGMENTS_DIR:-$ROOT_DIR/changelog.d}"
VERSION="${1:-}"
RELEASE_DATE="${2:-$(date +%F)}"

usage() {
  echo "Usage: $0 <version> [YYYY-MM-DD]" >&2
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

heading_for_type() {
  case "$1" in
    added) echo "Added" ;;
    changed) echo "Changed" ;;
    deprecated) echo "Deprecated" ;;
    removed) echo "Removed" ;;
    fixed) echo "Fixed" ;;
    security) echo "Security" ;;
    documentation) echo "Documentation" ;;
    *) return 1 ;;
  esac
}

normalize_fragment() {
  local file="$1"
  local output="$2"
  local line trimmed
  local count=0

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    trimmed="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -z "$trimmed" ] && continue
    case "$trimmed" in
      '<!--'*) continue ;;
      '- '*) printf '%s\n' "$trimmed" >> "$output" ;;
      *) printf -- '- %s\n' "$trimmed" >> "$output" ;;
    esac
    count=$((count + 1))
  done < "$file"

  [ "$count" -gt 0 ]
}

[ -n "$VERSION" ] || { usage; exit 2; }
[[ "$VERSION" =~ ^[0-9]+[.][0-9]+[.][0-9]+([-+][0-9A-Za-z.-]+)?$ ]] || fail "Version must look like X.Y.Z"
[[ "$RELEASE_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || fail "Date must look like YYYY-MM-DD"
[ -f "$CHANGELOG_FILE" ] || fail "Changelog not found: $CHANGELOG_FILE"
[ -d "$FRAGMENTS_DIR" ] || fail "Fragments directory not found: $FRAGMENTS_DIR"

grep -q '^## \[Unreleased\]' "$CHANGELOG_FILE" || fail "CHANGELOG.md must contain an [Unreleased] section"
existing_version_count="$(
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
if [ "$existing_version_count" -gt 0 ]; then
  fail "Version $VERSION already exists in CHANGELOG.md"
fi

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

TYPES=(added changed deprecated removed fixed security documentation)
for type in "${TYPES[@]}"; do
  : > "$WORK_DIR/$type"
done

fragment_count=0
bullet_count=0
fragment_files=()

while IFS= read -r file; do
  [ -n "$file" ] || continue
  base="$(basename "$file")"
  type="${base%.md}"
  type="${type##*.}"
  heading_for_type "$type" >/dev/null || fail "Unknown changelog fragment type in $base"

  tmp_fragment="$WORK_DIR/fragment"
  : > "$tmp_fragment"
  normalize_fragment "$file" "$tmp_fragment" || fail "Fragment has no release-note content: $base"
  cat "$tmp_fragment" >> "$WORK_DIR/$type"
  fragment_count=$((fragment_count + 1))
  bullet_count=$((bullet_count + $(wc -l < "$tmp_fragment" | tr -d ' ')))
  fragment_files+=("$file")
done < <(find "$FRAGMENTS_DIR" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort)

[ "$fragment_count" -gt 0 ] || fail "No changelog fragments found"
[ "$bullet_count" -gt 0 ] || fail "No release-note content found"

SECTION_FILE="$WORK_DIR/section.md"
{
  printf '## [%s] - %s\n\n' "$VERSION" "$RELEASE_DATE"
  for type in "${TYPES[@]}"; do
    [ -s "$WORK_DIR/$type" ] || continue
    printf '### %s\n' "$(heading_for_type "$type")"
    cat "$WORK_DIR/$type"
    printf '\n'
  done
} > "$SECTION_FILE"

UPDATED_CHANGELOG="$WORK_DIR/CHANGELOG.md"
awk -v section_file="$SECTION_FILE" '
  BEGIN {
    while ((getline line < section_file) > 0) {
      section = section line ORS
    }
    close(section_file)
    inserted = 0
    in_unreleased = 0
  }
  /^## \[Unreleased\]/ {
    in_unreleased = 1
    print
    next
  }
  in_unreleased && /^## / && !inserted {
    printf "\n%s", section
    inserted = 1
    in_unreleased = 0
  }
  { print }
  END {
    if (in_unreleased && !inserted) {
      printf "\n%s", section
    }
  }
' "$CHANGELOG_FILE" > "$UPDATED_CHANGELOG"

mv "$UPDATED_CHANGELOG" "$CHANGELOG_FILE"

for file in "${fragment_files[@]}"; do
  rm -f "$file"
done

echo "Prepared CHANGELOG.md for $VERSION"
