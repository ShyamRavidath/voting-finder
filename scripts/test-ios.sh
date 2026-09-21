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
DERIVED="${TMPDIR:-/tmp}/vote4u-test"

CREATED=()

cleanup() {
  for udid in "${CREATED[@]:-}"; do
    [ -n "$udid" ] && xcrun simctl delete "$udid" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

# Simulators are memory-hungry; several booted at once will exhaust a laptop.
xcrun simctl shutdown all >/dev/null 2>&1 || true

fresh_simulator() {
  FRESH_UDID=$(xcrun simctl create "Vote4U-Test-$$-${#CREATED[@]}" "$DEVICE_TYPE" "$RUNTIME")
  CREATED+=("$FRESH_UDID")
  xcrun simctl boot "$FRESH_UDID" >/dev/null
  xcrun simctl bootstatus "$FRESH_UDID" -b >/dev/null
}

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

echo ""
echo "Done."
