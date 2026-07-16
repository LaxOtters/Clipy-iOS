#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# 로컬 fixture와 GitHub Actions payload가 같은 label 해석 규칙을 타야 CI 라우팅을 재현할 수 있습니다.
LABELS_RAW="${CLIPY_IOS_PR_LABELS:-}"
DRY_RUN="${CLIPY_IOS_LABEL_ROUTER_DRY_RUN:-0}"

# GitHub Actions에서는 event payload를, 로컬 fixture에서는 env label 목록을 받습니다.
# 두 입력은 같은 label list로 정리하고, stdout에는 profile/scheme env만 내보냅니다.
usage() {
  cat >&2 <<USAGE
Usage: CLIPY_IOS_PR_LABELS=<newline-separated labels> $0

Inputs:
  CLIPY_IOS_PR_LABELS             optional newline-separated GitHub PR label names
  GITHUB_EVENT_PATH               optional GitHub pull_request event payload path
  CLIPY_IOS_LABEL_ROUTER_DRY_RUN  set to 1 to print the same env output without CI side effects

Output:
  CLIPY_IOS_VALIDATION_PROFILE=<profile>
  CLIPY_IOS_VALIDATION_SCHEMES=<schemes>
USAGE
}

read_labels_from_event() {
  local event_path="${GITHUB_EVENT_PATH:-}"

  if [[ -z "$event_path" ]]; then
    return 0
  fi

  if [[ ! -f "$event_path" ]]; then
    echo "GITHUB_EVENT_PATH does not exist: ${event_path}" >&2
    exit 2
  fi

  # GitHub 입력은 PR payload까지만 읽습니다. label 조회 권한이나 네트워크 상태가 CI 라우팅을 바꾸면 안 됩니다.
  python3 - "$event_path" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as event_file:
    payload = json.load(event_file)

for label in payload.get("pull_request", {}).get("labels", []):
    name = label.get("name")
    if name:
        print(name)
PY
}

read_labels() {
  if [[ -n "$LABELS_RAW" ]]; then
    printf '%s\n' "$LABELS_RAW"
    return
  fi

  read_labels_from_event
}

fail() {
  echo "$1" >&2
  usage
  exit 2
}

# label 분류 기준은 일부러 엄격하게 둡니다.
# 새 TYPE/AREA를 조용히 통과시키면 PR 변경보다 좁은 profile로 검증될 수 있습니다.
is_supported_type() {
  case "$1" in
    "TYPE | Feature"|"TYPE | Bug"|"TYPE | Refactor"|"TYPE | Docs"|"TYPE | Test"|"TYPE | Chore")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_supported_area() {
  case "$1" in
    "AREA | Docs"|"AREA | Project Setup"|"AREA | CI"|"AREA | AppMain"|"AREA | CoreDomain"|"AREA | CorePersistence"|"AREA | UI System"|"AREA | FeatureSession")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

has_area() {
  local expected="$1"
  local area_label

  for area_label in "${AREA_LABELS[@]}"; do
    if [[ "$area_label" == "$expected" ]]; then
      return 0
    fi
  done

  return 1
}

append_scheme_for_area() {
  case "$1" in
    "AREA | CoreDomain")
      SCHEMES+=("CoreDomain")
      ;;
    "AREA | CorePersistence")
      SCHEMES+=("CorePersistence")
      ;;
    "AREA | UI System")
      SCHEMES+=("CoreDesignSystem")
      ;;
    "AREA | FeatureSession")
      SCHEMES+=("FeatureSession")
      ;;
  esac
}

emit_env() {
  # stdout은 호출자가 그대로 $GITHUB_ENV에 붙입니다.
  # 사람이 읽는 로그가 섞이면 GitHub env file이 깨지므로 안내는 stderr에만 씁니다.
  printf 'CLIPY_IOS_VALIDATION_PROFILE=%s\n' "$PROFILE"
  printf 'CLIPY_IOS_VALIDATION_SCHEMES=%s\n' "$SCHEMES_OUTPUT"
}

LABELS=()
TYPE_LABELS=()
AREA_LABELS=()
UNSUPPORTED_LABELS=()
UNSUPPORTED_AREA_LABELS=()

# 여기서부터 입력 label을 TYPE, AREA, 미지원 label로 나눕니다.
# routing에 쓰지 않는 label도 조용히 무시하지 않습니다. label 기준과 resolver 기준이 달라지는 상황을 빨리 잡기 위해서입니다.
while IFS= read -r label; do
  [[ -z "$label" ]] && continue
  LABELS+=("$label")

  case "$label" in
    "TYPE | "*)
      TYPE_LABELS+=("$label")
      ;;
    "AREA | "*)
      AREA_LABELS+=("$label")
      if ! is_supported_area "$label"; then
        UNSUPPORTED_AREA_LABELS+=("$label")
      fi
      ;;
    *)
      UNSUPPORTED_LABELS+=("$label")
      ;;
  esac
done < <(read_labels)

if ((${#LABELS[@]} == 0)); then
  fail "No GitHub PR labels found. Set CLIPY_IOS_PR_LABELS or provide GITHUB_EVENT_PATH."
fi

if ((${#UNSUPPORTED_LABELS[@]} > 0)); then
  echo "Unsupported non-routing labels:" >&2
  printf '  %s\n' "${UNSUPPORTED_LABELS[@]}" >&2
  usage
  exit 2
fi

if ((${#TYPE_LABELS[@]} != 1)); then
  echo "Expected exactly one TYPE label, found ${#TYPE_LABELS[@]}." >&2
  if ((${#TYPE_LABELS[@]} > 0)); then
    printf '  %s\n' "${TYPE_LABELS[@]}" >&2
  fi
  usage
  exit 2
fi

if ((${#AREA_LABELS[@]} == 0)); then
  fail "At least one AREA label is required."
fi

if ((${#UNSUPPORTED_AREA_LABELS[@]} > 0)); then
  echo "Unsupported AREA labels:" >&2
  printf '  %s\n' "${UNSUPPORTED_AREA_LABELS[@]}" >&2
  usage
  exit 2
fi

TYPE_LABEL="${TYPE_LABELS[0]}"
if ! is_supported_type "$TYPE_LABEL"; then
  echo "Unsupported TYPE label: ${TYPE_LABEL}" >&2
  usage
  exit 2
fi

PROFILE=""
SCHEMES=()
SCHEMES_OUTPUT=""

for area_label in "${AREA_LABELS[@]}"; do
  append_scheme_for_area "$area_label"
done

# docs-only는 build를 생략하는 위험한 profile입니다.
# TYPE과 AREA가 모두 문서 변경을 가리킬 때만 허용하고, 다른 AREA가 섞이면 바로 실패시킵니다.
if [[ "$TYPE_LABEL" == "TYPE | Docs" ]]; then
  if ((${#AREA_LABELS[@]} != 1)) || ! has_area "AREA | Docs"; then
    echo "TYPE | Docs must be paired only with AREA | Docs." >&2
    printf 'AREA labels:\n' >&2
    printf '  %s\n' "${AREA_LABELS[@]}" >&2
    exit 2
  fi

  PROFILE="docs-only"
elif has_area "AREA | Docs"; then
  echo "AREA | Docs requires TYPE | Docs." >&2
  exit 2
elif has_area "AREA | CI"; then
  # CI label이 섞인 PR은 CI 검증을 유지하면서 함께 지정한 검증 scheme도 같은 plan에서 확인합니다.
  PROFILE="ci"
  if ((${#SCHEMES[@]} > 0)); then
    SCHEMES_OUTPUT="${SCHEMES[*]}"
  fi
elif has_area "AREA | Project Setup"; then
  PROFILE="project-setup"
else
  # 검증 scheme이 연결된 AREA는 AppMain 조립까지 봐야 하므로 integration profile로 보냅니다.
  if ((${#SCHEMES[@]} > 0)); then
    PROFILE="integration"
    SCHEMES_OUTPUT="${SCHEMES[*]}"
  elif has_area "AREA | AppMain"; then
    PROFILE="app-main"
  else
    fail "No validation profile mapping found for the provided labels."
  fi
fi

if [[ -z "$PROFILE" ]]; then
  fail "No validation profile mapping found for the provided labels."
fi

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Resolved iOS validation labels:" >&2
  printf '  %s\n' "${LABELS[@]}" >&2
fi

emit_env
