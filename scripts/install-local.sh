#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="Kubebar"
BUNDLE_ID="com.nextty.kubebar"
CONFIGURATION="${XCODE_CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${XCODE_DERIVED_DATA_PATH:-DerivedData}"
INSTALL_DIR="${KUBEBAR_INSTALL_DIR:-$HOME/Applications}"
BUILT_APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
INSTALL_APP_PATH="${INSTALL_DIR}/${APP_NAME}.app"

usage() {
  cat <<USAGE
Usage: ./scripts/install-local.sh [--help]

Builds ${APP_NAME} for local installation.

Environment:
  KUBEBAR_INSTALL_DIR       Destination directory. Default: ${HOME}/Applications
  XCODE_CONFIGURATION      Xcode build configuration. Default: Release
  XCODE_DERIVED_DATA_PATH  Xcode DerivedData path. Default: DerivedData

Options:
  --help                   Show this help message.
USAGE
}

invalid_app_bundle() {
  local label="$1"
  local reason="$2"

  echo "Invalid ${label} app bundle: ${reason}" >&2
  exit 1
}

plist_value() {
  local info_plist="$1"
  local key="$2"

  /usr/libexec/PlistBuddy -c "Print :${key}" "$info_plist" 2>/dev/null || true
}

verify_app_bundle() {
  local app_path="$1"
  local label="$2"
  local info_plist="${app_path}/Contents/Info.plist"
  local executable_path="${app_path}/Contents/MacOS/${APP_NAME}"
  local bundle_identifier
  local bundle_icon_file
  local lsui_element

  [ -d "$app_path" ] || invalid_app_bundle "$label" "missing directory at ${app_path}"
  [ -f "$info_plist" ] || invalid_app_bundle "$label" "missing Contents/Info.plist"

  bundle_identifier="$(plist_value "$info_plist" "CFBundleIdentifier")"
  [ "$bundle_identifier" = "$BUNDLE_ID" ] || invalid_app_bundle "$label" "CFBundleIdentifier is ${bundle_identifier:-missing}"

  bundle_icon_file="$(plist_value "$info_plist" "CFBundleIconFile")"
  [ "$bundle_icon_file" = "AppIcon" ] || invalid_app_bundle "$label" "CFBundleIconFile is ${bundle_icon_file:-missing}"

  lsui_element="$(plist_value "$info_plist" "LSUIElement")"
  case "$lsui_element" in
    true|1)
      ;;
    *)
      invalid_app_bundle "$label" "LSUIElement is ${lsui_element:-missing}"
      ;;
  esac

  [ -f "${app_path}/Contents/Resources/AppIcon.icns" ] || invalid_app_bundle "$label" "missing Contents/Resources/AppIcon.icns"
  [ -f "${app_path}/Contents/Resources/Assets.car" ] || invalid_app_bundle "$label" "missing Contents/Resources/Assets.car"
  [ -x "$executable_path" ] || invalid_app_bundle "$label" "missing executable Contents/MacOS/${APP_NAME}"
}

run_quality_gate() {
  XCODE_WORKSPACE="" \
    XCODE_PROJECT="${XCODE_PROJECT:-Kubebar.xcodeproj}" \
    XCODE_SCHEME="${XCODE_SCHEME:-Kubebar}" \
    XCODE_CONFIGURATION="$CONFIGURATION" \
    XCODE_DERIVED_DATA_PATH="$DERIVED_DATA_PATH" \
    ./scripts/swift-quality-gate.sh local
}

main() {
  if [ "$#" -gt 1 ]; then
    usage >&2
    exit 1
  fi

  case "${1:-}" in
    "")
      ;;
    "--help")
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac

  run_quality_gate
  verify_app_bundle "$BUILT_APP_PATH" "built"

  echo "Built app: ${BUILT_APP_PATH}"
}

main "$@"
