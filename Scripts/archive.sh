#!/bin/bash
# Archives Stash for the App Store and uploads it to App Store Connect (TestFlight / App Review).
#
#   TEAM_ID=ABCDE12345 BUILD=2 ./Scripts/archive.sh                 # archive + upload
#   TEAM_ID=ABCDE12345 BUILD=2 ./Scripts/archive.sh --export-only   # archive + export an .ipa, don't upload
#   ./Scripts/archive.sh --check                                    # unsigned Release build only (no account needed)
#
# TEAM_ID  your 10-character Apple Developer Team ID (developer.apple.com -> Membership)
# BUILD    the build number; every upload must be higher than the last one (default: a timestamp)
# Needs: Xcode signed in to your Apple ID (Settings -> Accounts), xcodegen installed.
# Each run writes to its own folder, build/appstore/<BUILD>, so nothing is ever deleted.
set -euo pipefail
cd "$(dirname "$0")/.."

SCHEME="Stash"
BUILD="${BUILD:-$(date +%y%m%d%H%M)}"
OUT="build/appstore/$BUILD"
mkdir -p "$OUT"

xcodegen generate >/dev/null

if [[ "${1:-}" == "--check" ]]; then
  xcodebuild archive -project Stash.xcodeproj -scheme "$SCHEME" -configuration Release \
    -destination 'generic/platform=iOS' -archivePath "$OUT/$SCHEME.xcarchive" \
    CODE_SIGNING_ALLOWED=NO CURRENT_PROJECT_VERSION="$BUILD" | tail -3
  echo "Unsigned Release archive OK: $OUT/$SCHEME.xcarchive"
  exit 0
fi

: "${TEAM_ID:?Set TEAM_ID to your 10-character Apple Developer Team ID}"

DEST="upload"; [[ "${1:-}" == "--export-only" ]] && DEST="export"
cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>$DEST</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
</dict></plist>
PLIST

xcodebuild archive -project Stash.xcodeproj -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$OUT/$SCHEME.xcarchive" \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM_ID" CURRENT_PROJECT_VERSION="$BUILD"

xcodebuild -exportArchive -archivePath "$OUT/$SCHEME.xcarchive" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" -exportPath "$OUT/export" -allowProvisioningUpdates

echo "Done - build $BUILD ($DEST). Processing in App Store Connect takes ~5-30 min."
