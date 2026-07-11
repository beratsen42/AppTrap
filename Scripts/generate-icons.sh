#!/bin/bash
#
# Generates all app-icon and menu-bar-icon sizes for the asset catalog
# from two source PNG files, using macOS's built-in `sips`.
#
# Usage:
#   ./Scripts/generate-icons.sh <app-icon-1024.png> <menubar-glyph.png>
#
# - <app-icon-1024.png>   Square master, ideally 1024x1024, with transparent
#                         corners outside the rounded-square artwork.
# - <menubar-glyph.png>   Square, black silhouette on a transparent background.
#
# Run it from the repository root. It writes the resized PNGs directly into
# AppTrap/Assets.xcassets, then you can build in Xcode.

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <app-icon-1024.png> <menubar-glyph.png>" >&2
    exit 1
fi

APP_ICON_SRC="$1"
MENUBAR_SRC="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS="$REPO_ROOT/AppTrap/Assets.xcassets"
APPICON_DIR="$ASSETS/AppIcon.appiconset"
MENUBAR_DIR="$ASSETS/MenuBarIcon.imageset"

for f in "$APP_ICON_SRC" "$MENUBAR_SRC"; do
    if [ ! -f "$f" ]; then
        echo "Error: file not found: $f" >&2
        exit 1
    fi
done

resize() {
    # resize <source> <pixels> <destination>
    sips -s format png -z "$2" "$2" "$1" --out "$3" >/dev/null
}

echo "Generating app icon sizes -> $APPICON_DIR"
resize "$APP_ICON_SRC" 16   "$APPICON_DIR/icon_16x16.png"
resize "$APP_ICON_SRC" 32   "$APPICON_DIR/icon_16x16@2x.png"
resize "$APP_ICON_SRC" 32   "$APPICON_DIR/icon_32x32.png"
resize "$APP_ICON_SRC" 64   "$APPICON_DIR/icon_32x32@2x.png"
resize "$APP_ICON_SRC" 128  "$APPICON_DIR/icon_128x128.png"
resize "$APP_ICON_SRC" 256  "$APPICON_DIR/icon_128x128@2x.png"
resize "$APP_ICON_SRC" 256  "$APPICON_DIR/icon_256x256.png"
resize "$APP_ICON_SRC" 512  "$APPICON_DIR/icon_256x256@2x.png"
resize "$APP_ICON_SRC" 512  "$APPICON_DIR/icon_512x512.png"
resize "$APP_ICON_SRC" 1024 "$APPICON_DIR/icon_512x512@2x.png"

echo "Generating menu bar icon sizes -> $MENUBAR_DIR"
resize "$MENUBAR_SRC" 18 "$MENUBAR_DIR/menubar_18.png"
resize "$MENUBAR_SRC" 36 "$MENUBAR_DIR/menubar_36.png"
resize "$MENUBAR_SRC" 54 "$MENUBAR_DIR/menubar_54.png"

echo "Done. Build in Xcode to pick up the new icons."
