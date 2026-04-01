#!/bin/bash
set -e
cd "$(dirname "$0")"

SDK=$(xcrun --show-sdk-path)
VFS="$(pwd)/vfs_overlay.yaml"
SOURCES=(Telecursor/*.swift)
APP="Telecursor.app"

echo "Compiling..."
swiftc \
  -target arm64-apple-macosx14.0 \
  -sdk "$SDK" \
  -Xfrontend -vfsoverlay -Xfrontend "$VFS" \
  -framework SwiftUI \
  -framework AppKit \
  -framework Carbon \
  -framework ApplicationServices \
  -framework ServiceManagement \
  -parse-as-library \
  -O \
  "${SOURCES[@]}" \
  -o Telecursor_bin

echo "Creating app bundle..."
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp Telecursor_bin "$APP/Contents/MacOS/Telecursor"
cp Telecursor/Info.plist "$APP/Contents/Info.plist"
sed -i '' \
  -e 's/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.telecursor.app/' \
  -e 's/\$(CURRENT_PROJECT_VERSION)/1/' \
  -e 's/\$(MARKETING_VERSION)/1.0.0/' \
  -e 's/\$(EXECUTABLE_NAME)/Telecursor/' \
  -e 's/\$(MACOSX_DEPLOYMENT_TARGET)/14.0/' \
  "$APP/Contents/Info.plist"

echo "Done! Run with: open Telecursor.app"
