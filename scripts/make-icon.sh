#!/usr/bin/env bash
# Builds Support/finello.icns from the 1024x1024 export.
#
# Support/finello.icon is the Icon Composer source of truth; open it there to
# change the artwork, re-export finello-1024.png, then run this. The .icns is
# what macOS 15 actually renders — Icon Composer's .icon format is the macOS 26
# pipeline, and finello ships to Sequoia.
set -euo pipefail
cd "$(dirname "$0")/.."

SOURCE="Support/finello-1024.png"
[ -f "$SOURCE" ] || { echo "missing $SOURCE" >&2; exit 1; }

SET=$(mktemp -d)/finello.iconset
mkdir -p "$SET"

for spec in "16:16x16" "32:16x16@2x" "32:32x32" "64:32x32@2x" \
            "128:128x128" "256:128x128@2x" "256:256x256" "512:256x256@2x" \
            "512:512x512" "1024:512x512@2x"; do
    px="${spec%%:*}"
    name="${spec##*:}"
    sips -z "$px" "$px" "$SOURCE" --out "$SET/icon_$name.png" >/dev/null
done

iconutil -c icns "$SET" -o Support/finello.icns
rm -rf "$(dirname "$SET")"
echo "Wrote Support/finello.icns ($(du -h Support/finello.icns | cut -f1))"
