#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="${CLIPY_IOS_SCHEME:-AppMain}"
WORKSPACE="${CLIPY_IOS_WORKSPACE:-Clipy.xcworkspace}"
MODE="${CLIPY_IOS_VALIDATION_MODE:-build-for-testing}"
CONFIGURATION="${CLIPY_IOS_XCODEBUILD_CONFIGURATION:-}"
DESTINATION="${CLIPY_IOS_DESTINATION:-}"
SIMULATOR_NAME="${CLIPY_IOS_SIMULATOR_NAME:-iPhone 17 Pro}"
# validate_ios_profile.sh가 방금 만든 workspace를 재사용할 때만 1로 둡니다.
# 직접 실행에서 켜면 오래된 workspace를 볼 수 있어서 존재 여부를 먼저 확인합니다.
SKIP_TUIST_PREP="${CLIPY_IOS_SKIP_TUIST_PREP:-0}"
EXPECTED_WORKSPACE_PATH="${WORKSPACE%/}"
XCODEBUILD_ARGS=()

# 실제 Tuist/xcodebuild 실행은 여기로 모읍니다.
# profile 실행과 직접 실행이 같은 mode/destination 규칙을 쓰게 해서 실패 재현 경로를 줄입니다.
resolve_test_destination() {
  # simulator 목록은 test mode에서만 읽습니다.
  # build/build-for-testing은 generic destination으로 보내 CI에서 시뮬레이터 부팅 비용을 피합니다.
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
  # 기본 로그는 줄이고 실패 지점만 보이게 둡니다. 상세 로그가 필요하면 CLIPY_XCODEBUILD_QUIET=0으로 끕니다.
  XCODEBUILD_ARGS+=("-quiet")
fi

# Release fallback처럼 build configuration 자체가 검증 계약일 때만 명시적으로 전달합니다.
# 빈 값이면 Xcode scheme의 기본 configuration을 그대로 사용합니다.
if [[ -n "$CONFIGURATION" ]]; then
  XCODEBUILD_ARGS+=("-configuration" "$CONFIGURATION")
fi

# Release configuration에서도 @testable contract test를 실행할 수 있게 test build에만
# testability를 켭니다. DEBUG compilation condition은 configuration을 그대로 따릅니다.
if [[ "$MODE" == "test" && "$CONFIGURATION" == "Release" ]]; then
  XCODEBUILD_ARGS+=("ENABLE_TESTABILITY=YES")
fi

# mode가 simulator 비용을 결정합니다.
# profile 실행과 직접 실행이 같은 값을 쓰므로 새 mode는 양쪽에서 같이 다뤄야 합니다.
case "$MODE" in
  # 기본 검증은 simulator boot 없이 AppMain 조립과 compile 가능 여부만 봅니다.
  build-for-testing)
    ACTION="build-for-testing"
    DESTINATION="${DESTINATION:-generic/platform=iOS Simulator}"
    ;;
  # compile 가능 여부만 빠르게 볼 때는 build mode를 명시합니다.
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

# skip flag는 validate_ios_profile.sh의 prepare_tuist_workspace가 성공한 뒤에만 안전합니다.
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
echo "Build configuration: ${CONFIGURATION:-scheme default}"
if [[ "$MODE" == "test" && "$CONFIGURATION" == "Release" ]]; then
  echo "Testability override: ENABLE_TESTABILITY=YES"
fi
echo "Using destination: ${DESTINATION}"

# 직접 실행은 Tuist graph를 다시 만들고, profile 안의 하위 실행만 재사용합니다.
# 이 경계를 지켜야 로컬에서는 오래된 생성물을 보지 않고, CI에서는 같은 workspace를 반복 생성하지 않습니다.
if [[ "$SKIP_TUIST_PREP" == "1" ]]; then
  echo "Skipping Tuist install/generate."
else
  mise exec -- tuist install
  # 검증 중 Xcode workspace를 열어 현재 작업 화면의 포커스를 바꾸지 않습니다.
  mise exec -- tuist generate --no-open
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
