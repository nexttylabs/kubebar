#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="$TMP_DIR/bin"
LAST_CAPTURE_DIR=""

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq -- "$text" "$file" || fail "Expected '$text' in $file"
}

assert_fails() {
  if "$@" >"$TMP_DIR/expected-failure.log" 2>&1; then
    fail "Expected command to fail: $*"
  fi
}

write_fake_tools() {
  mkdir -p "$FAKE_BIN"

  cat > "$FAKE_BIN/xcodegen" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
exit 0
SH

  cat > "$FAKE_BIN/xcodebuild" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

derived_data_path=""
marketing_version=""
build_number=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -derivedDataPath)
      shift
      derived_data_path="$1"
      ;;
    MARKETING_VERSION=*)
      marketing_version="${1#MARKETING_VERSION=}"
      ;;
    CURRENT_PROJECT_VERSION=*)
      build_number="${1#CURRENT_PROJECT_VERSION=}"
      ;;
  esac
  shift || true
done

if [ -z "$derived_data_path" ]; then
  echo "missing -derivedDataPath" >&2
  exit 1
fi

mkdir -p "$FAKE_CAPTURE_DIR"
{
  printf 'MARKETING_VERSION=%s\n' "$marketing_version"
  printf 'CURRENT_PROJECT_VERSION=%s\n' "$build_number"
} > "$FAKE_CAPTURE_DIR/xcodebuild.env"

plist_dir="$derived_data_path/Build/Products/Release/Kubebar.app/Contents"
mkdir -p "$plist_dir"
plist_marketing="${FAKE_PLIST_MARKETING_VERSION:-$marketing_version}"
plist_build="${FAKE_PLIST_BUILD_NUMBER:-$build_number}"
cat > "$plist_dir/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleShortVersionString</key>
  <string>$plist_marketing</string>
  <key>CFBundleVersion</key>
  <string>$plist_build</string>
</dict>
</plist>
PLIST
SH

  cat > "$FAKE_BIN/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = "rev-list" ] && [ "${2:-}" = "--count" ] && [ "${3:-}" = "HEAD" ]; then
  printf '%s\n' "${FAKE_GIT_COUNT:-314}"
  exit 0
fi
exec /usr/bin/git "$@"
SH

  cat > "$FAKE_BIN/codesign" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
exit 0
SH

  cat > "$FAKE_BIN/spctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
exit 0
SH

  cat > "$FAKE_BIN/zip" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ge 2 ]; then
  touch "$2"
fi
exit 0
SH

  chmod +x "$FAKE_BIN"/*
}

run_release() {
  local case_name="$1"
  local version="$2"
  shift 2

  local case_dir="$TMP_DIR/$case_name"
  local work_dir="$case_dir/work"
  local capture_dir="$case_dir/capture"
  mkdir -p "$work_dir" "$capture_dir"
  LAST_CAPTURE_DIR="$capture_dir"

  (
    cd "$work_dir"
    PATH="$FAKE_BIN:$PATH" \
      FAKE_CAPTURE_DIR="$capture_dir" \
      "$ROOT_DIR/scripts/build-release.sh" "$version" "$@"
  )
}

assert_capture() {
  local key="$1"
  local expected="$2"
  assert_contains "$LAST_CAPTURE_DIR/xcodebuild.env" "$key=$expected"
}

run_with_build_number_env() {
  BUILD_NUMBER=777 run_release env-override 0.9.1
}

run_with_invalid_build_number() {
  BUILD_NUMBER=build-7 run_release invalid-build 0.9.3
}

run_with_mismatched_plist() {
  FAKE_PLIST_BUILD_NUMBER=999 run_release mismatched-plist 0.9.4 55
}

write_fake_tools

run_release explicit-argument 0.9.0 42
assert_capture "MARKETING_VERSION" "0.9.0"
assert_capture "CURRENT_PROJECT_VERSION" "42"

run_with_build_number_env
assert_capture "MARKETING_VERSION" "0.9.1"
assert_capture "CURRENT_PROJECT_VERSION" "777"

FAKE_GIT_COUNT=314 run_release git-default 0.9.2
assert_capture "MARKETING_VERSION" "0.9.2"
assert_capture "CURRENT_PROJECT_VERSION" "314"

assert_fails run_with_invalid_build_number
assert_fails run_with_mismatched_plist

assert_contains "$ROOT_DIR/scripts/swift-quality-gate.sh" "test-release-build-version.sh"

echo "Release build version tests passed"
