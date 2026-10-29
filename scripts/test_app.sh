#!/usr/bin/env bash
# Build an app and run its unit and UI tests on an available iPhone simulator.
# Usage: scripts/test_app.sh examples/Tasks [extra xcodebuild args, e.g. -only-testing:TasksUITests]
set -euo pipefail

dir=${1:?usage: test_app.sh <app-directory> [xcodebuild args]}
shift
name=$(basename "$dir")
out=${DERIVED_DATA:-build/$name}
results="$out/results.xcresult"

# Prefer an iPhone on the newest installed iOS runtime.
device=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
runtimes = json.load(sys.stdin)["devices"]
for runtime in sorted(runtimes, key=lambda r: [int(x) for x in r.split("iOS-")[-1].split("-") if x.isdigit()], reverse=True):
    if "iOS" not in runtime:
        continue
    for d in runtimes[runtime]:
        if d["name"].startswith("iPhone"):
            print(d["udid"]); sys.exit()
sys.exit("no available iPhone simulator")
')

run_tests() {
  rm -rf "$results"
  # Parallel testing clones the simulator, which is slower than running in place for small apps.
  # Diagnostics collection after a failure can hang for 10 minutes, so it's off.
  xcodebuild test \
    -project "$dir/$name.xcodeproj" \
    -scheme "$name" \
    -destination "id=$device" \
    -derivedDataPath "$out" \
    -resultBundlePath "$results" \
    -parallel-testing-enabled NO \
    -collect-test-diagnostics never \
    -test-timeouts-enabled YES \
    -default-test-execution-time-allowance 300 \
    -quiet "$@"
}

failures() {
  xcrun xcresulttool get test-results summary --path "$results" --compact 2>/dev/null \
    | python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin).get("testFailures", []), indent=2))' || true
}

if run_tests "$@"; then
  echo "$name: build and tests passed"
  exit 0
fi

# The simulator occasionally fails to launch the test runner; that's not a test failure, so retry once.
if [ -d "$results" ] && failures | grep -q "Failed to install or launch the test runner"; then
  echo "$name: simulator failed to launch the test runner; retrying once" >&2
  xcrun simctl shutdown "$device" >/dev/null 2>&1 || true
  if run_tests "$@"; then
    echo "$name: build and tests passed"
    exit 0
  fi
fi

echo "$name: FAILED" >&2
[ -d "$results" ] && failures >&2
exit 1
