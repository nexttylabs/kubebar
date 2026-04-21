#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

CONFIGURATION="${XCODE_CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${XCODE_DERIVED_DATA_PATH:-DerivedData}"
APP_NAME="Kubebar"
BUNDLE_ID="com.nextty.kubebar"
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"

echo "Building and testing ${APP_NAME}"
XCODE_WORKSPACE="" \
  XCODE_PROJECT="${XCODE_PROJECT:-Kubebar.xcodeproj}" \
  XCODE_SCHEME="${XCODE_SCHEME:-Kubebar}" \
  XCODE_CONFIGURATION="$CONFIGURATION" \
  XCODE_DERIVED_DATA_PATH="$DERIVED_DATA_PATH" \
  ./scripts/swift-quality-gate.sh local

if [ ! -d "$APP_PATH" ]; then
  echo "Built app not found: $APP_PATH" >&2
  exit 1
fi

echo "Quitting existing ${APP_NAME} instance if present"
osascript -e "tell application id \"${BUNDLE_ID}\" to quit" >/dev/null 2>&1 || true

for _ in $(seq 1 20); do
  if ! pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  while IFS= read -r pid; do
    [ -n "$pid" ] && kill "$pid"
  done < <(pgrep -x "$APP_NAME")
fi

echo "Launching ${APP_PATH}"
open -n "$APP_PATH"

for _ in $(seq 1 50); do
  pid="$(pgrep -x "$APP_NAME" | head -n 1 || true)"
  if [ -n "$pid" ]; then
    echo "${APP_NAME} is running with PID ${pid}"
    echo "App path: ${APP_PATH}"
    exit 0
  fi
  sleep 0.2
done

echo "${APP_NAME} did not start within the expected timeout." >&2
exit 1
