#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="${CLIPY_IOS_SCHEME:-AppMain}"
WORKSPACE="${CLIPY_IOS_WORKSPACE:-Clipy.xcworkspace}"
DESTINATION="${CLIPY_IOS_DESTINATION:-}"

echo "Xcode:"
xcodebuild -version

echo "Tuist:"
mise exec -- tuist version

if [[ -z "$DESTINATION" ]]; then
  DEVICE_ID="$(xcrun simctl list devices available --json | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
devices = [
    device
    for runtime_devices in payload.get("devices", {}).values()
    for device in runtime_devices
    if device.get("isAvailable") and device.get("name", "").startswith("iPhone")
]

preferred = next((device for device in devices if device.get("name") == "iPhone 17 Pro"), None)
selected = preferred or (devices[0] if devices else None)

if selected is None:
    raise SystemExit("No available iPhone simulator found.")

print(selected["udid"])
')"
  DESTINATION="platform=iOS Simulator,id=${DEVICE_ID}"
fi

echo "Using destination: ${DESTINATION}"

mise exec -- tuist generate
xcodebuild test \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION"
