#!/bin/bash
set -e

if ! command -v xcodegen &> /dev/null; then
    echo "Installing xcodegen via Homebrew..."
    brew install xcodegen
fi

echo "Generating Xcode project..."
xcodegen generate

echo ""
echo "Done! Open Telecursor.xcodeproj in Xcode, then:"
echo "  1. Build & Run (Cmd+R)"
echo "  2. Grant Accessibility access when prompted"
echo "  3. The app appears in your menu bar as an arrow icon"
