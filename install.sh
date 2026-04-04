#!/usr/bin/env bash
set -euo pipefail

REPO="${BULLPEN_GITHUB_REPO:-markwolff/bullpen}"
DESTINATION="${DESTINATION:-/Applications}"
TMP_DIR="$(mktemp -d)"
ZIP_URL="https://github.com/${REPO}/releases/latest/download/Bullpen-macos.zip"
SHA_URL="https://github.com/${REPO}/releases/latest/download/Bullpen-macos.sha256"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ ! -d "$DESTINATION" || ! -w "$DESTINATION" ]]; then
  DESTINATION="$HOME/Applications"
fi

curl -fsSL "$ZIP_URL" -o "$TMP_DIR/Bullpen-macos.zip"
curl -fsSL "$SHA_URL" -o "$TMP_DIR/Bullpen-macos.sha256"

(cd "$TMP_DIR" && shasum -a 256 -c Bullpen-macos.sha256)

mkdir -p "$DESTINATION"
ditto -xk "$TMP_DIR/Bullpen-macos.zip" "$DESTINATION"
open "$DESTINATION/Bullpen.app"
