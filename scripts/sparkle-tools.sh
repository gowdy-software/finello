#!/usr/bin/env bash
# Locates Sparkle's command line tools inside the resolved SPM artifacts.
# They ship with the package, so there is nothing extra to install.
set -euo pipefail

find_sparkle_bin() {
    local candidate
    # CI builds into ./build; a local Xcode build resolves into DerivedData.
    for candidate in \
        "./build/SourcePackages/artifacts/sparkle/Sparkle/bin" \
        "$HOME/Library/Developer/Xcode/DerivedData"/finello-*/SourcePackages/artifacts/sparkle/Sparkle/bin
    do
        if [ -d "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done

    echo "Sparkle's tools are not resolved yet. Build the app once first:" >&2
    echo "  xcodebuild -project finello.xcodeproj -scheme finello build" >&2
    return 1
}
