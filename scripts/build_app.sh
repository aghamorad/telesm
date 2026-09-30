#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Telesm"
EXE="Telesm"

swift build -c release

rm -rf "dist/$APP_NAME.app"
mkdir -p "dist/$APP_NAME.app/Contents/MacOS" "dist/$APP_NAME.app/Contents/Resources"

cp ".build/release/$EXE" "dist/$APP_NAME.app/Contents/MacOS/$EXE"
cp "Resources/Info.plist" "dist/$APP_NAME.app/Contents/Info.plist"

if [ ! -f "Resources/AppIcon.icns" ]; then
  ./scripts/make_icon.sh
fi
cp "Resources/AppIcon.icns" "dist/$APP_NAME.app/Contents/Resources/AppIcon.icns"

codesign --force --sign - "dist/$APP_NAME.app" >/dev/null 2>&1 || true

echo "Built: dist/$APP_NAME.app"
