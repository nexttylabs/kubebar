#!/bin/bash
set -e

# Configuration
APP_NAME="Kubebar"
BUNDLE_ID="com.nextty.kubebar"
BUILD_DIR=".build/release"
RELEASE_DIR="release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
ZIP_NAME="$APP_NAME.zip"

echo "🚀 Starting release build for $APP_NAME..."

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
           BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
           MARKETING_VERSION="$1" \
           CURRENT_PROJECT_VERSION="1" \
           clean build

# 4. Copy and Package
echo "📂 Packaging app bundle..."
cp -R "$BUILD_DIR/Build/Products/Release/$APP_NAME.app" "$RELEASE_DIR/"

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
