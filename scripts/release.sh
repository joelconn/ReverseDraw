#!/bin/bash
# Archives RotaryDraw and uploads the build to TestFlight via App Store Connect.
#
# Required environment variables (App Store Connect API key — generate at
# appstoreconnect.apple.com > Users and Access > Integrations > App Store Connect API):
#   APP_STORE_CONNECT_KEY_ID      e.g. ABC123DEFG
#   APP_STORE_CONNECT_ISSUER_ID   e.g. 69a6de7f-... (UUID)
#   APP_STORE_CONNECT_KEY_PATH    path to the downloaded AuthKey_<KEY_ID>.p8 file
#
# Usage:
#   ./scripts/release.sh              bump build number only, archive, upload
#   ./scripts/release.sh 1.3          also set marketing version to 1.3 first

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$PROJECT_ROOT/RotaryDraw.xcodeproj/project.pbxproj"
EXPORT_OPTIONS="$PROJECT_ROOT/scripts/ExportOptions.plist"
BUILD_DIR="$PROJECT_ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/RotaryDraw.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"

NEW_MARKETING_VERSION="${1:-}"

for var in APP_STORE_CONNECT_KEY_ID APP_STORE_CONNECT_ISSUER_ID APP_STORE_CONNECT_KEY_PATH; do
  if [ -z "${!var:-}" ]; then
    echo "error: $var is not set." >&2
    echo "  Generate an API key at appstoreconnect.apple.com > Users and Access > Integrations > App Store Connect API," >&2
    echo "  then export APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, and APP_STORE_CONNECT_KEY_PATH (path to the .p8 file)." >&2
    exit 1
  fi
done

if [ ! -f "$APP_STORE_CONNECT_KEY_PATH" ]; then
  echo "error: no file found at APP_STORE_CONNECT_KEY_PATH ($APP_STORE_CONNECT_KEY_PATH)" >&2
  exit 1
fi

# --- Bump build number (always — required to be unique per TestFlight upload) ---
CURRENT_BUILD=$(grep -m1 "CURRENT_PROJECT_VERSION" "$PROJECT_FILE" | sed -E 's/[^0-9]*([0-9]+);.*/\1/')
NEW_BUILD=$((CURRENT_BUILD + 1))
sed -i '' "s/CURRENT_PROJECT_VERSION = $CURRENT_BUILD;/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PROJECT_FILE"
echo "Build number: $CURRENT_BUILD -> $NEW_BUILD"

# --- Optionally bump marketing version ---
if [ -n "$NEW_MARKETING_VERSION" ]; then
  CURRENT_MARKETING=$(grep -m1 "MARKETING_VERSION" "$PROJECT_FILE" | sed -E 's/[^0-9.]*([0-9.]+);.*/\1/')
  sed -i '' "s/MARKETING_VERSION = $CURRENT_MARKETING;/MARKETING_VERSION = $NEW_MARKETING_VERSION;/g" "$PROJECT_FILE"
  echo "Marketing version: $CURRENT_MARKETING -> $NEW_MARKETING_VERSION"
fi

# --- Archive for both macOS and iOS ---
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

for PLATFORM in macOS iOS; do
  ARCHIVE_NAME="RotaryDraw_$PLATFORM.xcarchive"
  ARCHIVE_FILE="$BUILD_DIR/$ARCHIVE_NAME"
  EXPORT_DIR="$BUILD_DIR/export_$PLATFORM"

  echo ""
  echo "Archiving for $PLATFORM..."

  "$XCODEBUILD" archive \
    -project "$PROJECT_ROOT/RotaryDraw.xcodeproj" \
    -scheme RotaryDraw \
    -configuration Release \
    -destination "generic/platform=$PLATFORM" \
    -archivePath "$ARCHIVE_FILE"

  # --- Export + upload to TestFlight in one step ---
  echo "Exporting and uploading $PLATFORM..."

  "$XCODEBUILD" -exportArchive \
    -archivePath "$ARCHIVE_FILE" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_DIR" \
    -authenticationKeyPath "$APP_STORE_CONNECT_KEY_PATH" \
    -authenticationKeyID "$APP_STORE_CONNECT_KEY_ID" \
    -authenticationKeyIssuerID "$APP_STORE_CONNECT_ISSUER_ID"
done

echo ""
echo "Uploaded build $NEW_BUILD to App Store Connect. Processing usually takes a few minutes —"
echo "check https://appstoreconnect.apple.com for TestFlight availability."
echo ""
echo "Don't forget to commit the version bump:"
echo "  git add RotaryDraw.xcodeproj/project.pbxproj && git commit -m 'Bump build to $NEW_BUILD'"
