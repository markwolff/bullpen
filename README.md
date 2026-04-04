# Bullpen

macOS menu bar app built with Swift.

## Run

```bash
swift build
swift run BullpenApp
```

Or launch it as a macOS app bundle:

```bash
./run.sh
```

## Install

Once a GitHub Release exists, users can install Bullpen directly with:

```bash
curl -fsSL https://raw.githubusercontent.com/markwolff/bullpen/main/install.sh | bash
```

The installer downloads the latest GitHub Release, verifies the checksum,
installs `Bullpen.app` into `/Applications` when possible, falls back to
`~/Applications` if needed, and opens it.

## Package

Build a distributable `.app` bundle and zip locally:

```bash
tools/package-macos.sh --output-dir .build/dist
```

If a Developer ID certificate and a `notarytool` keychain profile are available:

```bash
export APPLE_DEVELOPER_ID_APP="Developer ID Application: Your Name (TEAMID)"
export APPLE_NOTARY_KEYCHAIN_PROFILE="bullpen-notary"
tools/package-macos.sh --output-dir .build/dist --sign --notarize
```

The packaging script produces:
- `Bullpen.app`
- `Bullpen-macos.zip`
- `Bullpen-macos.sha256`

## Release

Create or update a GitHub Release with the packaged artifacts:

```bash
tools/release-macos.sh v0.1.0
```

This script uses the latest packaged zip/checksum and uploads them as:
- `Bullpen-macos.zip`
- `Bullpen-macos.sha256`

There is also a GitHub Actions workflow at
[release-macos.yml](/Users/mark.wolff/projects/bullpen/.github/workflows/release-macos.yml)
that signs, notarizes, packages, and uploads assets on tag pushes once the
required Apple signing secrets are configured.
