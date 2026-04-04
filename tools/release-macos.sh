#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  echo "Usage: tools/release-macos.sh <tag>" >&2
  exit 1
fi

OUTPUT_DIR="$ROOT/.build/dist/$TAG"
mkdir -p "$OUTPUT_DIR"

package_args=(
  --output-dir "$OUTPUT_DIR"
  --version "$TAG"
)

if [[ -n "${APPLE_DEVELOPER_ID_APP:-}" ]]; then
  package_args+=(--developer-id "$APPLE_DEVELOPER_ID_APP" --sign)
fi

if [[ -n "${APPLE_NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
  package_args+=(--notary-profile "$APPLE_NOTARY_KEYCHAIN_PROFILE" --notarize)
fi

"$ROOT/tools/package-macos.sh" "${package_args[@]}"

ZIP_PATH="$OUTPUT_DIR/Bullpen-macos.zip"
SHA_PATH="$OUTPUT_DIR/Bullpen-macos.sha256"

gh release view "$TAG" >/dev/null 2>&1 || gh release create "$TAG" --title "$TAG" --notes ""
gh release upload "$TAG" "$ZIP_PATH" "$SHA_PATH" --clobber
