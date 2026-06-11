#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# 로컬 검증에서 직접 돌릴 iOS module scheme만 열어둡니다.
# module을 추가하면 Tuist manifest, profile router, 이 whitelist를 같이 바꿉니다.
# 직접 실행 기본값은 CI 비용을 고려해 build-for-testing입니다. test가 필요하면 env로 명시합니다.
SUPPORTED_SCHEMES=(
  "AppMain"
  "CoreDomain"
  "CorePersistence"
  "FeatureSession"
)

usage() {
  cat >&2 <<USAGE
Usage: $0 <scheme>
       $0 --check <scheme>

Supported schemes:
  ${SUPPORTED_SCHEMES[*]}

Environment:
  CLIPY_IOS_VALIDATION_MODE   test | build-for-testing | build (default: build-for-testing)
  CLIPY_IOS_DESTINATION       optional xcodebuild destination override
  CLIPY_IOS_SIMULATOR_NAME    preferred simulator name for test mode
USAGE
}

is_supported_scheme() {
  local scheme="$1"
  local supported_scheme

  for supported_scheme in "${SUPPORTED_SCHEMES[@]}"; do
    if [[ "$scheme" == "$supported_scheme" ]]; then
      return 0
    fi
  done

  return 1
}

if [[ "${1:-}" == "--check" ]]; then
  if [[ "$#" -ne 2 ]]; then
    usage
    exit 2
  fi

  if is_supported_scheme "$2"; then
    exit 0
  fi

  echo "Unsupported iOS module scheme: ${2}" >&2
  usage
  exit 2
fi

if [[ "$#" -ne 1 ]]; then
  # scheme은 추론하지 않습니다. module 단위 검증은 호출자가 명시한 scheme만 실행합니다.
  usage
  exit 2
fi

SCHEME="$1"

# whitelist는 지금 repo에서 단독 검증 대상으로 열어둔 module 목록입니다.
# Tuist에 scheme이 있어도 이 목록에 없으면 profile router에서 먼저 의도를 정리합니다.
if ! is_supported_scheme "$SCHEME"; then
  # 잘못된 scheme 이름은 xcodebuild까지 보내지 않고 여기서 바로 멈춥니다.
  echo "Unsupported iOS module scheme: ${SCHEME}" >&2
  usage
  exit 2
fi

# 공통 xcodebuild/Tuist 흐름은 baseline script가 맡고, module script는 scheme 선택만 맡습니다.
export CLIPY_IOS_SCHEME="$SCHEME"
export CLIPY_IOS_VALIDATION_MODE="${CLIPY_IOS_VALIDATION_MODE:-build-for-testing}"

"$ROOT_DIR/scripts/validate_ios_baseline.sh"
