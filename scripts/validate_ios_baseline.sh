#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="${CLIPY_IOS_SCHEME:-AppMain}"
WORKSPACE="${CLIPY_IOS_WORKSPACE:-Clipy.xcworkspace}"
MODE="${CLIPY_IOS_VALIDATION_MODE:-build-for-testing}"
DESTINATION="${CLIPY_IOS_DESTINATION:-}"
SIMULATOR_NAME="${CLIPY_IOS_SIMULATOR_NAME:-iPhone 17 Pro}"
# 같은 profile 안에서 Tuist generate 결과를 다시 쓸 때만 1로 둡니다.
# 직접 실행에서 켜면 오래된 workspace를 볼 수 있어서 존재 여부를 먼저 확인합니다.
SKIP_TUIST_PREP="${CLIPY_IOS_SKIP_TUIST_PREP:-0}"
EXPECTED_WORKSPACE_PATH="${WORKSPACE%/}"
XCODEBUILD_ARGS=()

resolve_test_destination() {
  # simulator 목록은 test mode에서만 읽습니다.
  # build/build-for-testing은 generic destination을 써서 CI에서 시뮬레이터 부팅 비용을 피합니다.
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


# 선호 simulator가 없으면 사용 가능한 최신 iPhone runtime을 고릅니다.
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

if [[ "${CLIPY_XCODEBUILD_QUIET:-1}" == "1" ]]; then
  # 기본 로그는 줄이고, 실패 시 xcodebuild의 핵심 error만 보게 둡니다.
  # 상세 build log가 필요하면 CLIPY_XCODEBUILD_QUIET=0으로 끕니다.
  XCODEBUILD_ARGS+=("-quiet")
fi

# mode 선택이 이 스크립트의 비용을 결정합니다.
# profile router와 직접 실행이 같은 값을 쓰므로, 새 mode를 추가하면 docs도 같이 바꿉니다.
case "$MODE" in
  # 기본 검증은 simulator boot 없이 AppMain 조립과 compile 가능 여부만 봅니다.
  build-for-testing)
    ACTION="build-for-testing"
    DESTINATION="${DESTINATION:-generic/platform=iOS Simulator}"
    ;;
  # CI 비용을 더 줄여야 할 때는 build mode를 명시해서 더 가볍게 봅니다.
  build)
    ACTION="build"
    DESTINATION="${DESTINATION:-generic/platform=iOS Simulator}"
    ;;
  # unit test 실행은 simulator 비용이 있어서 필요한 작업에서만 명시합니다.
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

# skip flag는 prepare_tuist_workspace가 성공한 뒤에만 안전합니다.
# workspace가 없으면 하위 script를 단독으로 잘못 실행한 상황이므로 xcodebuild 전에 멈춥니다.
if [[ "$SKIP_TUIST_PREP" == "1" && ! -d "$EXPECTED_WORKSPACE_PATH" ]]; then
  echo "CLIPY_IOS_SKIP_TUIST_PREP=1 requires an existing workspace: ${WORKSPACE}" >&2
  echo "Run validate_ios_profile.sh or unset CLIPY_IOS_SKIP_TUIST_PREP." >&2
  exit 2
fi

echo "Xcode:"
xcodebuild -version

echo "Tuist:"
mise exec -- tuist version

echo "Validation mode: ${MODE}"
echo "Using destination: ${DESTINATION}"

# 직접 실행은 Tuist graph를 다시 만들고, profile 안의 하위 실행만 재사용합니다.
if [[ "$SKIP_TUIST_PREP" == "1" ]]; then
  echo "Skipping Tuist install/generate."
else
  mise exec -- tuist install
  mise exec -- tuist generate
fi

# 여기서부터 Tuist가 만든 workspace/scheme을 xcodebuild로 확인합니다.
# 실패하면 위쪽 mode/destination/workspace 로그부터 보고 재현 command를 좁힙니다.
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
