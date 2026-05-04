#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-LogResearchDemo}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 16 Pro,OS=latest}"
ARTIFACT_DIR="${ARTIFACT_DIR:-$ROOT_DIR/artifacts/logs}"
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$ARTIFACT_DIR/$STAMP"

mkdir -p "$RUN_DIR"

cd "$ROOT_DIR"

if [[ ! -d "$SCHEME.xcodeproj" ]]; then
  if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate >"$RUN_DIR/xcodegen.log" 2>&1
  else
    echo "Missing $SCHEME.xcodeproj and xcodegen is not installed." >&2
    exit 1
  fi
fi

set +e
xcodebuild \
  -project "$SCHEME.xcodeproj" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -resultBundlePath "$RUN_DIR/TestResults.xcresult" \
  test >"$RUN_DIR/xcodebuild-test.log" 2>&1
XCODEBUILD_STATUS=$?
set -e

xcrun simctl list devices available >"$RUN_DIR/simulators.log" 2>&1 || true

if command -v xcresulttool >/dev/null 2>&1 && [[ -d "$RUN_DIR/TestResults.xcresult" ]]; then
  xcrun xcresulttool get test-results summary --path "$RUN_DIR/TestResults.xcresult" >"$RUN_DIR/xcresult-summary.json" 2>&1 || true
fi

cat >"$RUN_DIR/summary.md" <<SUMMARY
# Xcode Log Collection Summary

- Timestamp: $STAMP
- Scheme: $SCHEME
- Destination: $DESTINATION
- xcodebuild exit code: $XCODEBUILD_STATUS

## Files

- xcodebuild-test.log: raw build and test output
- simulators.log: available simulator inventory
- TestResults.xcresult: structured Xcode result bundle, when available
- xcresult-summary.json: extracted test summary, when available

## Suggested AI Prompt

Use ../../prompts/analyze-xcode-logs.md and attach this summary plus the relevant log files.
SUMMARY

echo "Logs collected in: $RUN_DIR"
exit "$XCODEBUILD_STATUS"
