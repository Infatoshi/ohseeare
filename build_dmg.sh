#!/bin/bash

set -e

APP_NAME="ohseeare"
VERSION="1.1.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "Creating DMG: ${DMG_NAME}..."

# Build app first if needed
if [ ! -d "${APP_NAME}.app" ]; then
    ./build_app.sh
fi

# Create DMG with app included
hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_NAME}.app" -ov -format UDZO "${DMG_NAME}"

echo "✓ DMG created: ${DMG_NAME}"
echo "  Size: $(du -h "${DMG_NAME}" | cut -f1)"
