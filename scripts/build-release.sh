#!/usr/bin/env bash
set -euo pipefail

# Configuration
APP_NAME="Kubebar"
BUNDLE_ID="com.nextty.kubebar"
BUILD_DIR=".build/release"
RELEASE_DIR="release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
ZIP_NAME="$APP_NAME.zip"
RELEASE_VERSION="${1:-}"
EXPLICIT_BUILD_NUMBER="${2:-}"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

resolve_build_number() {
  if [ -n "$EXPLICIT_BUILD_NUMBER" ]; then
    printf '%s\n' "$EXPLICIT_BUILD_NUMBER"
    return 0
  fi

  if [ -n "${BUILD_NUMBER:-}" ]; then
    printf '%s\n' "$BUILD_NUMBER"
    return 0
  fi

  git rev-list --count HEAD
}

validate_release_version() {
  [ -n "$RELEASE_VERSION" ] || fail "Usage: $0 <version> [build-number]"

  case "$RELEASE_VERSION" in
    *[!A-Za-z0-9.+-]*)
      fail "Unsupported release version: use SemVer-compatible characters."
      ;;
  esac
}

validate_build_number() {
  local value="$1"
  [ -n "$value" ] || fail "Build number cannot be empty."

  case "$value" in
    *[!0-9]*)
      fail "Build number must be an integer."
      ;;
  esac
}

plist_value() {
  local key="$1"
  local plist="$APP_BUNDLE/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Print :$key" "$plist"
}

verify_bundle_versions() {
  local plist="$APP_BUNDLE/Contents/Info.plist"
  [ -f "$plist" ] || fail "Missing built app Info.plist."

  local actual_marketing_version
  local actual_build_number
  actual_marketing_version="$(plist_value CFBundleShortVersionString)"
  actual_build_number="$(plist_value CFBundleVersion)"

  [ "$actual_marketing_version" = "$RELEASE_VERSION" ] ||
    fail "Built app marketing version is $actual_marketing_version, expected $RELEASE_VERSION."
  [ "$actual_build_number" = "$BUILD_VERSION" ] ||
    fail "Built app build number is $actual_build_number, expected $BUILD_VERSION."
}

validate_release_version
BUILD_VERSION="$(resolve_build_number)"
validate_build_number "$BUILD_VERSION"

echo "🚀 Starting release build for $APP_NAME $RELEASE_VERSION ($BUILD_VERSION)..."

# 1. Clean and Prepare
rm -rf "$BUILD_DIR" "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# 2. Generate Project
xcodegen generate

# 3. Build Universal Binary
echo "📦 Building Universal binary (arm64 + x86_64)..."
xcodebuild -project "$APP_NAME.xcodeproj" \
           -scheme "$APP_NAME" \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR" \
           -destination "generic/platform=macOS" \
           MARKETING_VERSION="$RELEASE_VERSION" \
           CURRENT_PROJECT_VERSION="$BUILD_VERSION" \
           clean build

# 4. Copy and Package
echo "📂 Packaging app bundle..."
cp -R "$BUILD_DIR/Build/Products/Release/$APP_NAME.app" "$RELEASE_DIR/"

echo "🔢 Verifying app version metadata..."
verify_bundle_versions

# 5. Ad-hoc Signing
echo "✍️  Applying Ad-hoc signature..."
codesign --force --deep --sign - "$APP_BUNDLE"

# 6. Verify Signature
echo "🔍 Verifying signature..."
codesign --verify --deep --strict "$APP_BUNDLE"
spctl --assess --type execute "$APP_BUNDLE" || echo "Note: Gatekeeper will still flag this as unnotarized (expected)."

# 7. Zip the app
echo "🗜️  Creating $ZIP_NAME..."
cd "$RELEASE_DIR"
zip -r "../$ZIP_NAME" "$APP_NAME.app"
cd ..

echo "✅ Build complete: $ZIP_NAME"
