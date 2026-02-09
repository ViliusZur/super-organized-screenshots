#!/bin/bash
set -euo pipefail

APP_NAME="Super Organized Screenshots"
BUNDLE_ID="com.superorganized.screenshots"
EXECUTABLE_NAME="SuperOrganizedScreenshots"
VERSION="1.0.0"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
PROJECT_DIR="$ROOT_DIR/SuperOrganizedScreenshots"
BUILD_DIR="$ROOT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
ICON_SOURCE="$ROOT_DIR/screenshot-icon.png"

echo "==> Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ── Generate .icns from PNG ──────────────────────────────────────────
echo "==> Generating app icon..."
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

sips -z 16 16     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png"      > /dev/null
sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png"   > /dev/null
sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png"      > /dev/null
sips -z 64 64     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png"   > /dev/null
sips -z 128 128   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png"    > /dev/null
sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png"    > /dev/null
sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png"    > /dev/null
sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

ICNS_PATH="$BUILD_DIR/AppIcon.icns"
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"
rm -rf "$ICONSET_DIR"

# ── Build release binary ─────────────────────────────────────────────
echo "==> Building release binary..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

BINARY_PATH="$PROJECT_DIR/.build/release/$EXECUTABLE_NAME"
if [ ! -f "$BINARY_PATH" ]; then
    echo "ERROR: Binary not found at $BINARY_PATH"
    exit 1
fi

# ── Create .app bundle ───────────────────────────────────────────────
echo "==> Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"
cp "$ICNS_PATH"   "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Copy resource bundle if it exists
RESOURCE_BUNDLE=$(find "$PROJECT_DIR/.build/release" -name "*.bundle" -maxdepth 1 -type d | head -1)
if [ -n "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$APP_BUNDLE/Contents/Resources/"
fi

cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.photography</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>Super Organized Screenshots needs screen recording permission to capture screenshots.</string>
</dict>
</plist>
PLIST

echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "==> App bundle created at: $APP_BUNDLE"

# ── Create pretty DMG ────────────────────────────────────────────────
echo "==> Creating DMG..."
DMG_TEMP="$BUILD_DIR/dmg-temp"
DMG_RW="$BUILD_DIR/rw.dmg"
mkdir -p "$DMG_TEMP"
cp -R "$APP_BUNDLE" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

# Create read-write DMG first (needed for AppleScript styling)
rm -f "$DMG_RW"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDRW \
    -fs HFS+ \
    "$DMG_RW"

rm -rf "$DMG_TEMP"

# Mount and style with AppleScript
echo "==> Styling DMG window..."
DEVICE=$(hdiutil attach -readwrite -noverify "$DMG_RW" | awk '/Apple_HFS/{print $1}')
MOUNT_POINT="/Volumes/$APP_NAME"

sleep 2

osascript << EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        delay 1
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 200, 760, 540}
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 100
        set position of item "$APP_NAME.app" of container window to {130, 160}
        set position of item "Applications" of container window to {430, 160}
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

# Remove .fseventsd created by macOS during mount
rm -rf "$MOUNT_POINT/.fseventsd"

sync
sleep 1
hdiutil detach "$DEVICE"

# Convert to compressed read-only DMG
rm -f "$DMG_PATH"
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"
rm -f "$DMG_RW"

# Clean up
rm -f "$ICNS_PATH"

echo ""
echo "==> Done!"
echo "    DMG: $DMG_PATH"
echo ""
echo "    To install: Open the DMG and drag the app to Applications."
