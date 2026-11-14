#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUTPUT="${1:-$PWD/.artifacts/ci-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"
xcodebuild -version | tee "$OUTPUT/xcode.txt"
xcrun xcresulttool get test-results tests --help > "$OUTPUT/xcresulttool.txt"
if [ -z "${SIMULATOR_UDID:-}" ]; then
  SIMULATOR_UDID="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); runtimes=sorted((k for k in d["devices"] if "iOS" in k), key=lambda k: tuple(int(n) for n in k.split("iOS-")[-1].split("-")), reverse=True); devices=[v for k in runtimes for v in d["devices"][k] if v.get("isAvailable") and v["name"].startswith("iPhone")]; assert devices, "No available iPhone simulator"; print(devices[0]["udid"])')"
fi
printf '%s\n' "$SIMULATOR_UDID" > "$OUTPUT/simulator.txt"
bundle check
bundle exec pod install --deployment --project-directory=Example 2>&1 | tee "$OUTPUT/pod-install.log"
mkdir -p "$OUTPUT/example" "$OUTPUT/utilities"
xcodebuild test -workspace Example/MYKit.xcworkspace -scheme MYKit-Example -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" -derivedDataPath "$OUTPUT/DerivedData" -resultBundlePath "$OUTPUT/example/result.xcresult" -only-testing:MYKit_Tests 2>&1 | tee "$OUTPUT/example/command.log"
python3 ci/check-tests.py "$OUTPUT/example/result.xcresult" Example/Tests/acceptance.json
python3 Tests/run-tests.py --udid "$SIMULATOR_UDID" --output "$OUTPUT/safekit" --timeout 900
xcodebuild test -project Tests/UtilitiesTests.xcodeproj -scheme Utilities -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" -derivedDataPath "$OUTPUT/DerivedData-Utilities" -resultBundlePath "$OUTPUT/utilities/result.xcresult" -only-testing:UtilitiesTests 2>&1 | tee "$OUTPUT/utilities/command.log"
python3 ci/check-tests.py "$OUTPUT/utilities/result.xcresult" Tests/acceptance/Utilities.json
bundle exec pod lib lint --allow-warnings 2>&1 | tee "$OUTPUT/lint.log"
