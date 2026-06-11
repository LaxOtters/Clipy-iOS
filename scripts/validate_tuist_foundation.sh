#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-all}"

# build를 돌리기 전에 바로 잡을 수 있는 Tuist 규칙만 먼저 봅니다.
# --generated-artifacts-only는 docs-only처럼 build가 필요 없는 흐름에서 생성물만 확인할 때 씁니다.
if [[ "$MODE" != "all" && "$MODE" != "--generated-artifacts-only" ]]; then
  echo "Usage: $0 [--generated-artifacts-only]" >&2
  exit 2
fi

# 한 번 실행했을 때 고칠 지점을 최대한 같이 보려고 실패 개수만 모읍니다.
failures=0

report_failure() {
  local rule="$1"
  local message="$2"

  echo "${rule}: ${message}" >&2
  failures=$((failures + 1))
}

check_pattern_absent() {
  local rule="$1"
  local description="$2"
  local pattern="$3"
  local matched="0"
  local matches

  # Tuist helper 안에서는 raw TargetDependency를 만들 수 있습니다.
  # 여기서는 팀원이 직접 고치는 module manifest만 검사합니다.
  # rule 메시지는 한 번만 찍고, 실제 위치는 파일:라인으로 모두 보여줍니다.
  while IFS= read -r manifest; do
    matches="$(grep -nE "$pattern" "$manifest" || true)"
    if [[ -n "$matches" ]]; then
      if [[ "$matched" == "0" ]]; then
        report_failure "$rule" "$description"
        matched="1"
      fi
      echo "$matches" | sed "s#^#  ${manifest}:#" >&2
    fi
  done < <(find Modules -mindepth 2 -maxdepth 2 -name Project.swift -type f | sort)
}

check_tracked_generated_artifacts() {
  local generated_files

  # .gitignore가 있어도 이미 tracked 된 생성물은 git ls-files로 봐야 잡힙니다.
  # 새로 생긴 untracked 생성물은 PR 전에 git status --short로 따로 확인합니다.
  generated_files="$(git ls-files | grep -E '(^|/)([^/]+\.xcodeproj|[^/]+\.xcworkspace|Derived)(/|$)' || true)"

  if [[ -n "$generated_files" ]]; then
    report_failure "TUIST005" "tracked generated Xcode artifacts are not allowed"
    echo "$generated_files" | sed 's/^/  /' >&2
  fi
}

if [[ "$MODE" == "all" ]]; then
  echo "Checking Tuist module manifest policy..."
  # helper API가 바뀌면 이 rule과 Docs/Open/PROJECT_STRUCTURE.md의 manifest 작성 기준도 같이 바꿉니다.
  # 새 rule을 추가할 때는 TUIST00x 코드, 실패 메시지, 허용 예외를 한 세트로 맞춥니다.
  check_pattern_absent "TUIST001" "Modules/*/Project.swift must not use raw .project(...) dependencies" '\.project[[:space:]]*\('
  check_pattern_absent "TUIST002" "Modules/*/Project.swift must not use raw .external(...) dependencies" '\.external[[:space:]]*\('
  check_pattern_absent "TUIST003" "Modules/*/Project.swift must not construct TargetDependency directly" '\bTargetDependency\b'
  check_pattern_absent "TUIST004" "Modules/*/Project.swift must not call generic module factory helpers directly" '\b(makeFramework|makeProject)[[:space:]]*\('
fi

check_tracked_generated_artifacts

if ((failures > 0)); then
  echo "Tuist foundation validation failed with ${failures} issue(s)." >&2
  exit 1
fi

if [[ "$MODE" == "all" ]]; then
  echo "Tuist foundation validation passed."
else
  echo "Generated artifact preflight passed."
fi
