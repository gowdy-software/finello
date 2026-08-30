#!/usr/bin/env bash
# Exports the Sparkle private key so it can be pasted into the GitHub secret
# SPARKLE_PRIVATE_KEY. The file is written to disk — delete it once pasted.
#
# This key is the only thing standing between her Mac and a malicious update,
# because finello is not notarized. Treat the file like a password.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/sparkle-tools.sh

OUT="sparkle-private-key.txt"
BIN=$(find_sparkle_bin)
"$BIN/generate_keys" -x "$OUT"

echo
echo "Written to $OUT (git-ignored)."
echo
echo "1. Open https://github.com/gowdy-software/finello/settings/secrets/actions"
echo "2. New repository secret, named exactly: SPARKLE_PRIVATE_KEY"
echo "3. Paste the whole contents of $OUT"
echo "4. Then delete it:  rm $OUT"
