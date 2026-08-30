#!/usr/bin/env bash
# Builds, signs and packages a release, then updates the appcast.
#
#   ./scripts/release.sh 0.2.0
#
# Afterwards: commit appcast.xml, tag, push, and attach the zip from dist/ to
# a GitHub release of the same tag. The repo must stay public so finello can
# fetch its own updates without a credential (ADR 0004).
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/sparkle-tools.sh

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "usage: $0 <marketing-version>   e.g. $0 0.2.0" >&2
    exit 1
fi

PUBKEY=$(/usr/libexec/PlistBuddy -c "Print :SUPublicEDKey" Support/Info.plist 2>/dev/null || echo "")
if [ -z "$PUBKEY" ]; then
    echo "SUPublicEDKey is empty in Support/Info.plist." >&2
    echo "Run ./scripts/generate-keys.sh first — without it finello will not update." >&2
    exit 1
fi

# Sparkle compares CFBundleVersion, so it must increase every release.
BUILD=$(git rev-list --count HEAD)

echo "==> Building finello $VERSION (build $BUILD)"
rm -rf dist build
xcodebuild -project finello.xcodeproj -scheme finello -configuration Release \
    -destination 'platform=macOS' -derivedDataPath build \
    MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD" \
    clean build

APP="build/Build/Products/Release/finello.app"
[ -d "$APP" ] || { echo "no app at $APP" >&2; exit 1; }

mkdir -p dist
# ditto rather than zip: it preserves the bundle's symlinks and signature.
ditto -c -k --sequesterRsrc --keepParent "$APP" "dist/finello-$VERSION.zip"

# Sparkle shows release notes from an .html file sitting beside the archive
# with a matching name. Without one she gets an empty "what's new" panel.
NOTES="release-notes/$VERSION.html"
if [ -f "$NOTES" ]; then
    cp "$NOTES" "dist/finello-$VERSION.html"
else
    echo "!! No $NOTES — this release will show an empty changelog." >&2
    echo "   Write one and re-run to give her something to read." >&2
fi

echo "==> Signing the update"
BIN=$(find_sparkle_bin)
"$BIN/generate_appcast" dist/

echo
echo "Built dist/finello-$VERSION.zip and updated dist/appcast.xml"
echo
echo "Next:"
echo "  cp dist/appcast.xml appcast.xml"
echo "  git add appcast.xml && git commit -m \"Release $VERSION\""
echo "  git tag v$VERSION && git push && git push --tags"
echo "  gh release create v$VERSION dist/finello-$VERSION.zip --title \"finello $VERSION\""
