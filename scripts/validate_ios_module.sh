#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# profile에서 넘어온 scheme을 baseline script로 넘기는 얇은 문지기입니다.
# 단독 검증 대상으로 열어둔 iOS scheme만 받고, 나머지는 xcodebuild 전에 실패시킵니다.
# module을 추가하면 Tuist manifest, profile 선택 기준, label resolver, 허용 scheme 목록을 같이 바꿉니다.
# 기본값은 CI 비용을 줄이기 위해 build-for-testing입니다. test가 필요하면 mode를 명시합니다.
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
  # profile plan을 만들 때는 --check로 scheme 오타만 먼저 봅니다.
  # 실제 build는 PLAN 실행 단계에서 같은 script가 다시 맡습니다.
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
  # module 검증은 대상을 추론하지 않습니다.
  # label resolver나 로컬 호출자가 고른 scheme만 실행해야 검증 범위가 흔들리지 않습니다.
  usage
  exit 2
fi

SCHEME="$1"

# Tuist에 scheme이 있어도 이 목록에 없으면 검증 대상으로 열지 않습니다.
# 새 scheme은 profile 기준과 label resolver 기준까지 정리한 뒤 추가합니다.
if ! is_supported_scheme "$SCHEME"; then
  # 잘못된 scheme 이름은 xcodebuild까지 보내지 않고 여기서 멈춥니다.
  echo "Unsupported iOS module scheme: ${SCHEME}" >&2
  usage
  exit 2
fi

# 공통 xcodebuild/Tuist 흐름은 baseline script가 맡고, module script는 scheme 선택만 맡습니다.
export CLIPY_IOS_SCHEME="$SCHEME"
export CLIPY_IOS_VALIDATION_MODE="${CLIPY_IOS_VALIDATION_MODE:-build-for-testing}"

"$ROOT_DIR/scripts/validate_ios_baseline.sh"
