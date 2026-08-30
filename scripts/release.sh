#!/usr/bin/env bash
# Builds, signs and packages a release, then updates the appcast.
#
#   ./scripts/release.sh 0.2.0
#
# Signs with the EdDSA key in your login keychain, or with $SPARKLE_PRIVATE_KEY
# when one is set (which is how CI does it). Produces dist/ — it does not
# publish. Publishing is .github/workflows/release.yml, or the printed steps.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/sparkle-tools.sh

REPO="gowdy-software/finello"

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

# Sparkle shows release notes from an .html file beside the archive. Shipping
# without one gives her a blank "what's new" panel, so refuse by default.
NOTES="release-notes/$VERSION.html"
if [ ! -f "$NOTES" ]; then
    if [ "${ALLOW_BLANK_NOTES:-0}" = "1" ]; then
        echo "!! No $NOTES — shipping a blank changelog because ALLOW_BLANK_NOTES=1." >&2
    else
        echo "Missing $NOTES." >&2
        echo "Write it, or set ALLOW_BLANK_NOTES=1 to ship without a changelog." >&2
        exit 1
    fi
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
[ -f "$NOTES" ] && cp "$NOTES" "dist/finello-$VERSION.html"

echo "==> Signing the update"
BIN=$(find_sparkle_bin)
# The archive lives on the GitHub release, not next to the appcast. Without
# this prefix Sparkle derives the download URL from the feed's own directory
# and every update 404s.
PREFIX="https://github.com/$REPO/releases/download/v$VERSION/"

if [ -n "${SPARKLE_PRIVATE_KEY:-}" ]; then
    printf '%s' "$SPARKLE_PRIVATE_KEY" \
        | "$BIN/generate_appcast" --ed-key-file - --download-url-prefix "$PREFIX" dist/
else
    "$BIN/generate_appcast" --download-url-prefix "$PREFIX" dist/
fi

echo
echo "Built dist/finello-$VERSION.zip and updated dist/appcast.xml"
echo
echo "To publish by hand (CI does this for you on a tag push):"
echo "  cp dist/appcast.xml appcast.xml"
echo "  git add appcast.xml && git commit -m \"Publish appcast for $VERSION\""
echo "  git tag v$VERSION && git push && git push --tags"
echo "  gh release create v$VERSION dist/finello-$VERSION.zip --title \"finello $VERSION\""
