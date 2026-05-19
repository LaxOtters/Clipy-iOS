#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="${CLIPY_IOS_SCHEME:-AppMain}"
WORKSPACE="${CLIPY_IOS_WORKSPACE:-Clipy.xcworkspace}"
MODE="${CLIPY_IOS_VALIDATION_MODE:-build-for-testing}"
DESTINATION="${CLIPY_IOS_DESTINATION:-}"
SIMULATOR_NAME="${CLIPY_IOS_SIMULATOR_NAME:-iPhone 17 Pro}"
XCODEBUILD_ARGS=()

if [[ "${CLIPY_XCODEBUILD_QUIET:-1}" == "1" ]]; then
  XCODEBUILD_ARGS+=("-quiet")
fi

resolve_test_destination() {
  xcrun simctl list devices available --json | CLIPY_IOS_SIMULATOR_NAME="$SIMULATOR_NAME" python3 -c '
import json
import os
import re
import sys

preferred_name = os.environ.get("CLIPY_IOS_SIMULATOR_NAME", "")
payload = json.load(sys.stdin)
devices = []


def runtime_version(runtime):
    return tuple(int(part) for part in re.findall(r"\d+", runtime))


for runtime, runtime_devices in payload.get("devices", {}).items():
    for device in runtime_devices:
        if device.get("isAvailable") and device.get("name", "").startswith("iPhone"):
            devices.append({**device, "runtimeVersion": runtime_version(runtime)})

preferred = next((device for device in devices if device.get("name") == preferred_name), None)
selected = preferred or (max(devices, key=lambda device: (device["runtimeVersion"], device.get("name", ""))) if devices else None)

if selected is None:
    raise SystemExit("No available iPhone simulator found.")

print(selected["udid"])
'
}

echo "Xcode:"
xcodebuild -version

echo "Tuist:"
mise exec -- tuist version

echo "Validation mode: ${MODE}"

case "$MODE" in
  build-for-testing|build)
    ACTION="build-for-testing"
    DESTINATION="${DESTINATION:-generic/platform=iOS Simulator}"
    ;;
  test)
    ACTION="test"
    if [[ -z "$DESTINATION" ]]; then
      DEVICE_ID="$(resolve_test_destination)"
      DESTINATION="platform=iOS Simulator,id=${DEVICE_ID},arch=arm64"
    fi
    ;;
  *)
    echo "Unsupported CLIPY_IOS_VALIDATION_MODE: ${MODE}" >&2
    echo "Use one of: build-for-testing, build, test" >&2
    exit 2
    ;;
esac

echo "Using destination: ${DESTINATION}"

mise exec -- tuist install
mise exec -- tuist generate

if ((${#XCODEBUILD_ARGS[@]})); then
  xcodebuild "$ACTION" \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    "${XCODEBUILD_ARGS[@]}"
else
  xcodebuild "$ACTION" \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION"
fi
