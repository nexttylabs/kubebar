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
}

main "$@"
