#!/bin/bash
# Build and run Bullpen as a proper .app bundle so macOS registers it
# as a GUI app (NSStatusItem, activation policy, etc. all work correctly).
set -euo pipefail

APP_NAME="Bullpen"
BUNDLE_DIR=".build/${APP_NAME}.app"
CONTENTS="${BUNDLE_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"

# 1. Build
swift build "$@"

# 2. Create .app bundle structure
mkdir -p "${MACOS}"

# 3. Copy binary
cp .build/debug/BullpenApp "${MACOS}/BullpenApp"

# 4. Write Info.plist (LSUIElement makes it a menu-bar-only app — no Dock icon)
cat > "${CONTENTS}/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BullpenApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.bullpen.app</string>
    <key>CFBundleName</key>
    <string>Bullpen</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

# 5. Launch
echo "Launching ${BUNDLE_DIR}..."
open "${BUNDLE_DIR}"
