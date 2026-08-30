#!/usr/bin/env bash
# Locates Sparkle's command line tools inside the resolved SPM artifacts.
# They ship with the package, so there is nothing extra to install.
set -euo pipefail

find_sparkle_bin() {
    local found
    found=$(find "$HOME/Library/Developer/Xcode/DerivedData"/finello-*/SourcePackages/artifacts/sparkle/Sparkle/bin \
        -maxdepth 1 -type d 2>/dev/null | head -1)
    if [ -z "$found" ]; then
        echo "Sparkle's tools are not resolved yet. Build the app once first:" >&2
        echo "  xcodebuild -project finello.xcodeproj -scheme finello build" >&2
        return 1
    fi
    echo "$found"
}
