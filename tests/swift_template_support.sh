#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
WORK_DIR="$TMP_DIR/template-copy"
BIN_DIR="$TMP_DIR/bin"

cleanup() {
  rm -rf "$TMP_DIR"
}

if [ "${KEEP_TMP:-0}" != "1" ]; then
  trap cleanup EXIT
else
  echo "Keeping temp directory: $TMP_DIR"
fi

mkdir -p "$BIN_DIR"

cp -R "$ROOT_DIR/." "$WORK_DIR"
rm -rf "$WORK_DIR/.git"

cat > "$BIN_DIR/swift" <<'EOF'
#!/usr/bin/env bash
echo "swift $*" >&2
exit 0
EOF

cat > "$BIN_DIR/xcodebuild" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$*" == *"-list -json"* ]]; then
  printf '{ "project": { "schemes": ["DemoApp"] } }\n'
  exit 0
fi

if [[ "$*" == *"build"* ]]; then
  echo "build ok"
  exit 0
fi

if [[ "$*" == *"test"* ]]; then
  echo "test ok"
  exit 0
fi

echo "xcodebuild ok"
EOF

chmod +x "$BIN_DIR/swift" "$BIN_DIR/xcodebuild"

(
  cd "$WORK_DIR"
  printf 'Demo App\n5\n1\n' | ./init.sh >/tmp/swift-template-init.log 2>&1
)

test -f "$WORK_DIR/AGENTS.md"
grep -q "Swift Guide" "$WORK_DIR/AGENTS.md"
test -f "$WORK_DIR/scripts/swift-quality-gate.sh"
grep -q 'swift-quality-gate.sh ci' "$WORK_DIR/.github/workflows/ci.yml"
grep -q 'swift-quality-gate.sh local' "$WORK_DIR/.githooks/pre-push"
test ! -d "$WORK_DIR/_lang"
test ! -f "$WORK_DIR/init.sh"

mkdir -p "$WORK_DIR/DemoApp.xcodeproj"

DEV_SETUP_OUTPUT="$TMP_DIR/dev-setup.log"
(
  cd "$WORK_DIR"
  PATH="$BIN_DIR:$PATH" ./scripts/dev-setup.sh --check-only
) >"$DEV_SETUP_OUTPUT" 2>&1

grep -q 'Detected project language: swift' "$DEV_SETUP_OUTPUT"

QUALITY_GATE_OUTPUT="$TMP_DIR/swift-quality-gate.log"
(
  cd "$WORK_DIR"
  PATH="$BIN_DIR:$PATH" XCODE_DESTINATION='platform=iOS Simulator,name=iPhone 16' ./scripts/swift-quality-gate.sh local
) >"$QUALITY_GATE_OUTPUT" 2>&1

grep -q 'Using Xcode scheme: DemoApp' "$QUALITY_GATE_OUTPUT"
grep -q 'Running Swift build check' "$QUALITY_GATE_OUTPUT"
grep -q 'Running Swift test check' "$QUALITY_GATE_OUTPUT"

echo "PASS: Swift template support"
