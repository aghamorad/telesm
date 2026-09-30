#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SOURCE="${1:-Resources/AppIconSource.png}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cp scripts/prepare_icon.swift "$TMP/prepare_icon.swift"
swift "$TMP/prepare_icon.swift" "$SOURCE" "$TMP/icon_1024.png"

ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET"

for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$TMP/icon_1024.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" "$TMP/icon_1024.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET" -o "Resources/AppIcon.icns"
echo "Wrote Resources/AppIcon.icns from $SOURCE"
