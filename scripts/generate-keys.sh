#!/usr/bin/env bash
# Run once, ever. Creates the EdDSA key pair Sparkle uses to verify updates.
#
# The private key goes into your login keychain and must never be committed:
# anyone holding it can push a signed update to her Mac. The public half is
# printed for you to paste into Support/Info.plist as SUPublicEDKey.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/sparkle-tools.sh

BIN=$(find_sparkle_bin)
"$BIN/generate_keys"

echo
echo "Paste the public key above into Support/Info.plist under SUPublicEDKey,"
echo "then commit that change. The private key stays in your keychain only."
