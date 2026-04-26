#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

write_changelog() {
  local path="$1"
  cat > "$path" <<'EOF'
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.1.0] - 2026-04-23

### Added
- Initial release.
EOF
}

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "Expected '$text' in $file"
}

assert_not_contains() {
  local file="$1"
  local text="$2"
  if grep -Fq -- "$text" "$file"; then
    fail "Did not expect '$text' in $file"
  fi
}

assert_fails() {
  if "$@" >/dev/null 2>&1; then
    fail "Expected command to fail: $*"
  fi
}

run_prepare() {
  CHANGELOG_FILE="$1" CHANGELOG_FRAGMENTS_DIR="$2" "$ROOT_DIR/scripts/prepare-changelog-release.sh" "$3" "$4"
}

run_extract() {
  CHANGELOG_FILE="$1" "$ROOT_DIR/scripts/extract-release-notes.sh" "$2"
}

case_dir="$TMP_DIR/happy"
mkdir -p "$case_dir/fragments"
write_changelog "$case_dir/CHANGELOG.md"
printf -- '- Add release-note validation.\n' > "$case_dir/fragments/release-validation.added.md"
printf 'Fix empty release notes.\n' > "$case_dir/fragments/empty-notes.fixed.md"
run_prepare "$case_dir/CHANGELOG.md" "$case_dir/fragments" "0.2.0" "2026-04-26"
assert_contains "$case_dir/CHANGELOG.md" "## [0.2.0] - 2026-04-26"
assert_contains "$case_dir/CHANGELOG.md" "### Added"
assert_contains "$case_dir/CHANGELOG.md" "- Add release-note validation."
assert_contains "$case_dir/CHANGELOG.md" "### Fixed"
assert_contains "$case_dir/CHANGELOG.md" "- Fix empty release notes."
[ ! -e "$case_dir/fragments/release-validation.added.md" ] || fail "Merged fragment was not removed"
run_extract "$case_dir/CHANGELOG.md" "0.2.0" > "$case_dir/notes.md"
assert_contains "$case_dir/notes.md" "- Add release-note validation."
assert_contains "$case_dir/notes.md" "- Fix empty release notes."
assert_not_contains "$case_dir/notes.md" "Initial release."

case_dir="$TMP_DIR/multiple"
mkdir -p "$case_dir/fragments"
write_changelog "$case_dir/CHANGELOG.md"
printf 'First change.\n' > "$case_dir/fragments/first.changed.md"
printf -- '- Second change.\n' > "$case_dir/fragments/second.changed.md"
run_prepare "$case_dir/CHANGELOG.md" "$case_dir/fragments" "0.3.0" "2026-04-26"
assert_contains "$case_dir/CHANGELOG.md" "- First change."
assert_contains "$case_dir/CHANGELOG.md" "- Second change."

case_dir="$TMP_DIR/no-fragments"
mkdir -p "$case_dir/fragments"
write_changelog "$case_dir/CHANGELOG.md"
cp "$case_dir/CHANGELOG.md" "$case_dir/before.md"
assert_fails run_prepare "$case_dir/CHANGELOG.md" "$case_dir/fragments" "0.2.0" "2026-04-26"
cmp "$case_dir/CHANGELOG.md" "$case_dir/before.md" >/dev/null || fail "No-fragment failure changed changelog"

case_dir="$TMP_DIR/duplicate"
mkdir -p "$case_dir/fragments"
write_changelog "$case_dir/CHANGELOG.md"
printf 'Duplicate version.\n' > "$case_dir/fragments/duplicate.added.md"
assert_fails run_prepare "$case_dir/CHANGELOG.md" "$case_dir/fragments" "0.1.0" "2026-04-26"

case_dir="$TMP_DIR/unknown-type"
mkdir -p "$case_dir/fragments"
write_changelog "$case_dir/CHANGELOG.md"
printf 'Unknown category.\n' > "$case_dir/fragments/unknown.misc.md"
assert_fails run_prepare "$case_dir/CHANGELOG.md" "$case_dir/fragments" "0.2.0" "2026-04-26"

case_dir="$TMP_DIR/empty-fragment"
mkdir -p "$case_dir/fragments"
write_changelog "$case_dir/CHANGELOG.md"
printf '\n\n' > "$case_dir/fragments/empty.fixed.md"
assert_fails run_prepare "$case_dir/CHANGELOG.md" "$case_dir/fragments" "0.2.0" "2026-04-26"

case_dir="$TMP_DIR/extract-missing"
write_changelog "$case_dir.md"
assert_fails run_extract "$case_dir.md" "9.9.9"

case_dir="$TMP_DIR/extract-empty"
cat > "$case_dir.md" <<'EOF'
# Changelog

## [Unreleased]

## [0.2.0] - 2026-04-26

## [0.1.0] - 2026-04-23

### Added
- Initial release.
EOF
assert_fails run_extract "$case_dir.md" "0.2.0"

case_dir="$TMP_DIR/extract-duplicate"
cat > "$case_dir.md" <<'EOF'
# Changelog

## [Unreleased]

## [0.2.0] - 2026-04-26

### Added
- First entry.

## [0.2.0] - 2026-04-27

### Fixed
- Duplicate entry.
EOF
assert_fails run_extract "$case_dir.md" "0.2.0"

case_dir="$TMP_DIR/extract-heading-like-body"
cat > "$case_dir.md" <<'EOF'
# Changelog

## [Unreleased]

## [0.2.0] - 2026-04-26

### Added
- Document the literal text ## [0.2.0] - in release notes examples.
EOF
run_extract "$case_dir.md" "0.2.0" > "$TMP_DIR/heading-like-body-notes.md"
assert_contains "$TMP_DIR/heading-like-body-notes.md" "literal text ## [0.2.0] -"

echo "Changelog tooling tests passed"
