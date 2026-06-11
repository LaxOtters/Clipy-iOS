#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# PR1에서는 검증 가능한 iOS module을 명시적으로 열어둡니다.
# module을 추가하면 Tuist manifest와 함께 이 whitelist도 갱신합니다.
SUPPORTED_SCHEMES=(
  "AppMain"
  "CoreDomain"
  "CorePersistence"
  "FeatureSession"
)

usage() {
  cat >&2 <<USAGE
Usage: $0 <scheme>

Supported schemes:
  ${SUPPORTED_SCHEMES[*]}

Environment:
  CLIPY_IOS_VALIDATION_MODE   test | build-for-testing | build (default: test)
  CLIPY_IOS_DESTINATION       optional xcodebuild destination override
  CLIPY_IOS_SIMULATOR_NAME    preferred simulator name for test mode
USAGE
}

if [[ "$#" -ne 1 ]]; then
  usage
  exit 2
fi

SCHEME="$1"

is_supported="0"
for supported_scheme in "${SUPPORTED_SCHEMES[@]}"; do
  if [[ "$SCHEME" == "$supported_scheme" ]]; then
    is_supported="1"
    break
  fi
done

if [[ "$is_supported" != "1" ]]; then
  echo "Unsupported iOS module scheme: ${SCHEME}" >&2
  usage
  exit 2
fi

export CLIPY_IOS_SCHEME="$SCHEME"
export CLIPY_IOS_VALIDATION_MODE="${CLIPY_IOS_VALIDATION_MODE:-test}"

"$ROOT_DIR/scripts/validate_ios_baseline.sh"
