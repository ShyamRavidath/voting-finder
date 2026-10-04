#!/usr/bin/env bash
# Full iOS test run: unit tests, UI smoke tests, and both notification-permission directions.
#
#   ./scripts/test-ios.sh
#
# Why this is not just `xcodebuild test`:
#
# iOS asks for notification permission once and remembers the answer for the lifetime of the
# simulator. Neither `simctl uninstall` nor `simctl privacy reset` clears it, so the allow and
# deny tests cannot both see an alert on the same device. Each therefore gets a throwaway
# simulator, created and destroyed here.
#
# Order also matters: the allow test runs before the unit tests, because ReminderScheduler needs
# authorization before UNUserNotificationCenter will queue anything. Without it those tests skip
# rather than fail — honest, but not coverage.
set -euo pipefail

DEVICE_TYPE="${DEVICE_TYPE:-iPhone 17}"
RUNTIME="${RUNTIME:-$(xcrun simctl list runtimes | grep -oE 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]+' | tail -1)}"
PROJECT="$(cd "$(dirname "$0")/.." && pwd)/ios/Vote4U.xcodeproj"
# Overridable so CI can put the build products somewhere it can archive them; TMPDIR on a
# hosted runner is a per-process path that need not survive into the next workflow step.
DERIVED="${DERIVED:-${TMPDIR:-/tmp}/vote4u-test}"

CREATED=()

cleanup() {
  for udid in "${CREATED[@]:-}"; do
    [ -n "$udid" ] && xcrun simctl delete "$udid" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

# Simulators are memory-hungry; several booted at once will exhaust a laptop.
xcrun simctl shutdown all >/dev/null 2>&1 || true

BUNDLE_ID="com.shyamravidath.Vote4U"
APP_PATH="$DERIVED/Build/Products/Debug-iphonesimulator/Vote4U.app"

check_widget_device_family() {
  local plist="$1/PlugIns/Vote4UWidgets.appex/Info.plist"
  # This branch has a widget; the containing app remains iPhone-only, but Apple's extension
  # submission rule requires the extension itself to support both iPhone and iPad.
  if [ -d "$(dirname "$plist")" ]; then
    if [ ! -f "$plist" ] || ! python3 -c 'import plistlib, sys; families = plistlib.load(open(sys.argv[1], "rb"))["UIDeviceFamily"]; sys.exit(0 if set(families) == {1, 2} else 1)' "$plist"; then
      echo "✗ Widget extension must declare iPhone and iPad: $plist" >&2
      exit 1
    fi
    echo "  Widget extension supports iPhone and iPad"
  fi
}

fresh_simulator() {
  FRESH_UDID=$(xcrun simctl create "Vote4U-Test-$$-${#CREATED[@]}" "$DEVICE_TYPE" "$RUNTIME")
  CREATED+=("$FRESH_UDID")
  xcrun simctl boot "$FRESH_UDID" >/dev/null
  xcrun simctl bootstatus "$FRESH_UDID" -b >/dev/null

  # A brand-new simulator is cold enough that the first app launch can take longer than a UI
  # test's patience: the permission alert then never appears inside the timeout and the failure
  # looks like a missing alert rather than a slow boot. Warm it with a throwaway launch first.
  if [ -d "$APP_PATH" ]; then
    xcrun simctl install "$FRESH_UDID" "$APP_PATH" >/dev/null 2>&1 || true
    xcrun simctl launch "$FRESH_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    sleep 8
    xcrun simctl terminate "$FRESH_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  fi
}

# Build once up front so the warm-up above has an app bundle to launch.
#
# `generic/platform=iOS Simulator` rather than `name=$DEVICE_TYPE`: a bare device name is resolved
# against the newest installed runtime, so pinning the deployment-era runtime
# (DEVICE_TYPE='iPhone 15 Pro' RUNTIME=…iOS-17-5) failed here with "no available devices matched"
# — there is no iPhone 15 Pro on iOS 27. A generic destination needs no device at all; the tests
# below still run on the exact simulators this script creates.
echo "▸ Building"
mkdir -p "$DERIVED"
BUILD_LOG="$DERIVED/build-for-testing.log"
xcodebuild build-for-testing -project "$PROJECT" -scheme Vote4U \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$DERIVED" >"$BUILD_LOG" 2>&1 || {
    echo "build-for-testing failed. Last 40 log lines:" >&2
    tail -40 "$BUILD_LOG" >&2
    exit 1
  }
check_widget_device_family "$APP_PATH"

run() {
  local label="$1" udid="$2" status log
  shift 2
  mkdir -p "$DERIVED"
  log="$DERIVED/${label//[^[:alnum:]]/_}.log"
  echo ""
  echo "▸ $label"
  if xcodebuild test -project "$PROJECT" -scheme Vote4U -destination "id=$udid" \
       -derivedDataPath "$DERIVED" "$@" >"$log" 2>&1; then
    status=0
  else
    status=$?
  fi

  grep -E "Test Case .*(passed|failed)|Executed .* test|error: -\[|TEST (SUCCEEDED|FAILED)" "$log" || true
  if (( status != 0 )); then
    echo "✗ $label failed (xcodebuild exit $status). Last 80 log lines:" >&2
    tail -80 "$log" >&2
    return "$status"
  fi
}

# One simulator for the allow path plus everything that needs authorization.
fresh_simulator
MAIN="$FRESH_UDID"
run "Notification permission — allow" "$MAIN" \
  -only-testing:Vote4UUITests/ReminderPermissionUITests/testAllowingNotificationsLeavesTheToggleOn

run "Unit tests + UI smoke tests" "$MAIN" \
  -only-testing:Vote4UTests -only-testing:Vote4UUITests/AppSmokeUITests

xcrun simctl shutdown "$MAIN" >/dev/null 2>&1 || true

# The deny path needs a device that has never been asked.
fresh_simulator
DENY="$FRESH_UDID"
run "Notification permission — deny" "$DENY" \
  -only-testing:Vote4UUITests/ReminderPermissionUITests/testDenyingNotificationsFlipsTheToggleBackAndExplains

# The UI tests drive canned API responses through APIStub, which invents polling venues. Never
# showing a voter a location the data does not support is rule #1 (and guideline 1.1.6), so prove
# the stub really is compiled out of Release rather than trusting the #if.
echo ""
echo "▸ Release build contains no stubbed venues"
RELEASE_DERIVED="$DERIVED-release"
if xcodebuild build -project "$PROJECT" -scheme Vote4U -configuration Release \
     -destination "generic/platform=iOS Simulator" \
     -derivedDataPath "$RELEASE_DERIVED" >"$DERIVED/release-build.log" 2>&1; then
  BINARY="$RELEASE_DERIVED/Build/Products/Release-iphonesimulator/Vote4U.app/Vote4U"
  check_widget_device_family "$RELEASE_DERIVED/Build/Products/Release-iphonesimulator/Vote4U.app"
  if strings "$BINARY" | grep -qE "Roxbury Community Center|-stubPolling|-startTab"; then
    echo "✗ DEBUG-only strings survived into the Release binary" >&2
    exit 1
  fi
  echo "  ok"
else
  echo "✗ Release build failed. Last 40 log lines:" >&2
  tail -40 "$DERIVED/release-build.log" >&2
  exit 1
fi

echo ""
echo "Done."
