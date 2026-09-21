#!/usr/bin/env bash
# Captures the App Store screenshot set at the required 6.9" size (1320x2868).
#
#   ./scripts/capture-screenshots.sh
#
# Relies on the DEBUG-only -startTab / -startZip launch arguments in the app, so no UI automation
# is needed. Re-run after any UI change; the output is committed so the listing and the app can
# be compared.
set -euo pipefail

DEVICE="${DEVICE:-iPhone 18 Pro Max}"
BUNDLE_ID="com.shyamravidath.Vote4U"
OUT="$(cd "$(dirname "$0")/.." && pwd)/ios/screenshots"
DERIVED="${TMPDIR:-/tmp}/vote4u-screenshots"

echo "Building for ${DEVICE}…"
xcodebuild -project ios/Vote4U.xcodeproj -scheme Vote4U \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath "$DERIVED" build >/dev/null

xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b >/dev/null

# A consistent, uncluttered status bar. Apple's own screenshots read 9:41.
xcrun simctl ui "$DEVICE" appearance light >/dev/null
xcrun simctl ui "$DEVICE" content_size medium >/dev/null
xcrun simctl status_bar "$DEVICE" override \
  --time "9:41" --cellularMode active --cellularBars 4 \
  --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100

xcrun simctl install "$DEVICE" "$DERIVED/Build/Products/Debug-iphonesimulator/Vote4U.app"
xcrun simctl privacy "$DEVICE" grant location "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl location "$DEVICE" set 34.0736,-118.4004 2>/dev/null || true

mkdir -p "$OUT"

shoot() {
  local name="$1"; shift
  xcrun simctl terminate "$DEVICE" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$DEVICE" "$BUNDLE_ID" "$@" >/dev/null
  sleep 12  # allow live endpoints to finish a cold serverless start before capturing
  xcrun simctl io "$DEVICE" screenshot "$OUT/$name" >/dev/null
  echo "  $name"
}

echo "Capturing…"
shoot 1-vote-results.png     -startTab vote -startZip 90210
shoot 2-home-countdown.png   -startTab home
shoot 3-electoral-map.png    -startTab map
shoot 4-official-sources.png -startTab vote
shoot 5-news.png             -startTab news

echo "Done → $OUT"
