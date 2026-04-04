#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="Bullpen"
BUNDLE_ID="com.bullpen.app"
OUTPUT_DIR="$ROOT/.build/dist"
VERSION="${VERSION:-}"
BUILD_CONFIGURATION="release"
DEVELOPER_ID_APP="${APPLE_DEVELOPER_ID_APP:-}"
NOTARY_PROFILE="${APPLE_NOTARY_KEYCHAIN_PROFILE:-}"
NOTARIZE=0
SIGN=0

usage() {
  cat <<'EOF'
Usage: tools/package-macos.sh [options]

Options:
  --output-dir <dir>      Output directory for packaged artifacts
  --version <version>     Version string to embed in Info.plist
  --developer-id <name>   Developer ID Application signing identity
  --notary-profile <name> notarytool keychain profile name
  --sign                  Sign the app bundle
  --notarize              Notarize and staple the app bundle (implies --sign)
  --help                  Show this help

Environment fallbacks:
  VERSION
  APPLE_DEVELOPER_ID_APP
  APPLE_NOTARY_KEYCHAIN_PROFILE
EOF
}

while (($#)); do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --developer-id)
      DEVELOPER_ID_APP="$2"
      shift 2
      ;;
    --notary-profile)
      NOTARY_PROFILE="$2"
      shift 2
      ;;
    --sign)
      SIGN=1
      shift
      ;;
    --notarize)
      NOTARIZE=1
      SIGN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  VERSION="$(git describe --tags --always --dirty)"
fi

if [[ "$SIGN" -eq 1 && -z "$DEVELOPER_ID_APP" ]]; then
  echo "Signing requested but no Developer ID identity was provided." >&2
  exit 1
fi

if [[ "$NOTARIZE" -eq 1 && -z "$NOTARY_PROFILE" ]]; then
  echo "Notarization requested but no notary profile was provided." >&2
  exit 1
fi

APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ZIP_PATH="$OUTPUT_DIR/Bullpen-macos.zip"
SHA_PATH="$OUTPUT_DIR/Bullpen-macos.sha256"
SUBMISSION_ZIP="$OUTPUT_DIR/Bullpen-macos.notary.zip"

rm -rf "$APP_BUNDLE" "$ZIP_PATH" "$SHA_PATH" "$SUBMISSION_ZIP"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swift build -c "$BUILD_CONFIGURATION" --product BullpenApp

cp "$ROOT/.build/$BUILD_CONFIGURATION/BullpenApp" "$MACOS_DIR/BullpenApp"

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>BullpenApp</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>15.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
EOF

if [[ "$SIGN" -eq 1 ]]; then
  codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "$DEVELOPER_ID_APP" \
    "$APP_BUNDLE"
fi

if [[ "$NOTARIZE" -eq 1 ]]; then
  ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$SUBMISSION_ZIP"
  xcrun notarytool submit "$SUBMISSION_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_BUNDLE"
fi

ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
(
  cd "$OUTPUT_DIR"
  shasum -a 256 "$(basename "$ZIP_PATH")" > "$(basename "$SHA_PATH")"
)

echo "APP_BUNDLE=$APP_BUNDLE"
echo "ZIP_PATH=$ZIP_PATH"
echo "SHA256_PATH=$SHA_PATH"
