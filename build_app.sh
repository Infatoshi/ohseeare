#!/bin/bash

set -e

APP_NAME="ohseeare"
VERSION="1.1.0"
APP_PATH="${APP_NAME}.app"
CONTENTS="${APP_PATH}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"
INFO_PLIST="${CONTENTS}/Info.plist"

echo "Building ${APP_NAME} app bundle..."

# Create app bundle structure
rm -rf "${APP_PATH}"
mkdir -p "${MACOS}"
mkdir -p "${RESOURCES}"

# Compile Swift binary
echo "Compiling..."
swiftc -parse-as-library -o "${MACOS}/${APP_NAME}" ohseeare.swift

# Create Info.plist
echo "Creating Info.plist..."
cat > "${INFO_PLIST}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.infatoshi.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Set executable permissions
chmod +x "${MACOS}/${APP_NAME}"

echo "✓ App bundle created: ${APP_PATH}"
