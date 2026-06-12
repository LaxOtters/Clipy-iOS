#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROFILE="${CLIPY_IOS_VALIDATION_PROFILE:-}"
SCHEMES_RAW="${CLIPY_IOS_VALIDATION_SCHEMES:-}"
DRY_RUN="${CLIPY_IOS_VALIDATION_DRY_RUN:-0}"
# 기본값은 simulator를 띄우지 않는 build-for-testing입니다.
# 실제 test가 필요한 작업만 CLIPY_IOS_VALIDATION_MODE=test를 명시합니다.
export CLIPY_IOS_VALIDATION_MODE="${CLIPY_IOS_VALIDATION_MODE:-build-for-testing}"

usage() {
  cat >&2 <<USAGE
Usage: CLIPY_IOS_VALIDATION_PROFILE=<profile> $0

Profiles:
  project-setup
  ci
  app-main
  tuist-foundation
  module
  integration
  docs-only

Inputs:
  CLIPY_IOS_VALIDATION_PROFILE   required canonical profile id
  CLIPY_IOS_VALIDATION_SCHEMES    required for module/integration; comma or whitespace separated scheme names
  CLIPY_IOS_CHANGED_FILES        optional newline-separated file paths
  CLIPY_IOS_CHANGED_FILES_FILE   optional file containing newline-separated paths
  CLIPY_IOS_VALIDATION_DRY_RUN   set to 1 to print the command plan only
  CLIPY_IOS_VALIDATION_MODE      build-for-testing | build | test (default: build-for-testing)
USAGE
}

if [[ -z "$PROFILE" ]]; then
  # profile이 없으면 넓은 검증으로 추정하지 않습니다.
  # 비용이 큰 검증을 실수로 돌릴 수 있어서 바로 멈춥니다.
  echo "CLIPY_IOS_VALIDATION_PROFILE is required." >&2
  usage
  exit 2
fi

# dry-run에서도 mode 오타는 먼저 잡습니다.
# 잘못된 plan이 PR이나 CI 설정으로 넘어가는 걸 막기 위해서입니다.
case "$CLIPY_IOS_VALIDATION_MODE" in
  build-for-testing|build|test)
    ;;
  *)
    echo "Unsupported CLIPY_IOS_VALIDATION_MODE: ${CLIPY_IOS_VALIDATION_MODE}" >&2
    echo "Use one of: build-for-testing, build, test" >&2
    exit 2
    ;;
esac

PLAN=()
VALIDATION_SCHEMES=()
PROJECT_SETUP_SCHEMES=(
  "CoreDomain"
  "CorePersistence"
  "FeatureSession"
)

# PLAN은 kind|description|command|arg1|arg2 형태로 쌓습니다.
# dry-run에 보이는 plan과 실제 실행 plan이 갈라지지 않게 같은 배열을 씁니다.
add_script_step() {
  local description="$1"
  local entry="script|${description}"
  shift

  while (($# > 0)); do
    entry="${entry}|$1"
    shift
  done

  PLAN+=("$entry")
}

# build-script는 첫 실행 직전에 Tuist workspace를 한 번만 만듭니다.
# 이후 child script는 같은 workspace를 써서 CI에서 generate를 반복하지 않습니다.
add_build_step() {
  local description="$1"
  local entry="build-script|${description}"
  shift

  while (($# > 0)); do
    entry="${entry}|$1"
    shift
  done

  PLAN+=("$entry")
}

add_function_step() {
  local description="$1"
  local function_name="$2"

  PLAN+=("function|${description}|${function_name}")
}

run_command() {
  # CI 로그에서 실제로 돈 command를 바로 찾을 수 있게 먼저 출력합니다.
  echo "+ $*"
  "$@"
}

format_command() {
  local first="1"

  while (($# > 0)); do
    if [[ "$first" == "1" ]]; then
      printf '%q' "$1"
      first="0"
    else
      printf ' %q' "$1"
    fi
    shift
  done
}

read_validation_schemes() {
  local normalized
  local scheme

  VALIDATION_SCHEMES=()
  normalized="${SCHEMES_RAW//$'\n'/ }"
  normalized="${normalized//,/ }"

  set -f
  for scheme in $normalized; do
    [[ -z "$scheme" ]] && continue
    VALIDATION_SCHEMES+=("$scheme")
  done
  set +f
}

check_validation_schemes() {
  local scheme

  # scheme 오타는 Tuist generate 전에 잡습니다.
  # 실제 build 검증은 아래 plan에서 같은 validate_ios_module.sh가 다시 맡습니다.
  for scheme in "${VALIDATION_SCHEMES[@]}"; do
    "$ROOT_DIR/scripts/validate_ios_module.sh" --check "$scheme"
  done
}

require_validation_schemes() {
  read_validation_schemes

  if ((${#VALIDATION_SCHEMES[@]} == 0)); then
    echo "${PROFILE} profile requires CLIPY_IOS_VALIDATION_SCHEMES." >&2
    echo "Example: CLIPY_IOS_VALIDATION_PROFILE=${PROFILE} CLIPY_IOS_VALIDATION_SCHEMES=FeatureSession $0" >&2
    exit 2
  fi

  check_validation_schemes
}

add_module_steps() {
  local scheme

  require_validation_schemes

  for scheme in "${VALIDATION_SCHEMES[@]}"; do
    add_build_step "Module ${scheme}" "$ROOT_DIR/scripts/validate_ios_module.sh" "$scheme"
  done
}

add_project_setup_module_steps() {
  local scheme

  VALIDATION_SCHEMES=("${PROJECT_SETUP_SCHEMES[@]}")
  check_validation_schemes

  for scheme in "${PROJECT_SETUP_SCHEMES[@]}"; do
    add_build_step "Module ${scheme}" "$ROOT_DIR/scripts/validate_ios_module.sh" "$scheme"
  done
}

read_changed_files() {
  # GitHub API나 label 조회는 PR2에서 붙입니다.
  # PR1에서는 호출자가 넘긴 changed files만 보고 docs-only 여부를 확인합니다.
  if [[ -n "${CLIPY_IOS_CHANGED_FILES:-}" ]]; then
    printf '%s\n' "$CLIPY_IOS_CHANGED_FILES"
    return
  fi

  if [[ -n "${CLIPY_IOS_CHANGED_FILES_FILE:-}" ]]; then
    if [[ ! -f "$CLIPY_IOS_CHANGED_FILES_FILE" ]]; then
      echo "CLIPY_IOS_CHANGED_FILES_FILE does not exist: ${CLIPY_IOS_CHANGED_FILES_FILE}" >&2
      exit 2
    fi
    cat "$CLIPY_IOS_CHANGED_FILES_FILE"
  fi
}

is_docs_only_path() {
  local path="$1"

  # docs-only는 공개 문서와 GitHub template 변경만 허용합니다.
  # script, Tuist manifest, source가 섞이면 build를 생략하면 안 됩니다.
  case "$path" in
    Docs/*|README.md|Docs.md|AGENTS.md|.github/ISSUE_TEMPLATE/*|.github/PULL_REQUEST_TEMPLATE/*|.github/pull_request_template.md)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

validate_docs_only_changed_files() {
  local changed_files
  local invalid_paths=()
  local path

  # changed files 입력이 없으면 docs-only라고 보지 않습니다.
  # 첫 구현에서는 자동 diff 분석 대신 명시 입력만 받습니다.
  changed_files="$(read_changed_files)"

  if [[ -z "$changed_files" ]]; then
    echo "docs-only profile requires CLIPY_IOS_CHANGED_FILES or CLIPY_IOS_CHANGED_FILES_FILE." >&2
    exit 2
  fi

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if ! is_docs_only_path "$path"; then
      invalid_paths+=("$path")
    fi
  done <<< "$changed_files"

  if ((${#invalid_paths[@]} > 0)); then
    # docs-only로 돌렸지만 코드성 파일이 섞인 경우입니다.
    # 이때는 더 넓은 profile을 골라 다시 실행합니다.
    echo "docs-only profile received non-doc/template paths:" >&2
    printf '  %s\n' "${invalid_paths[@]}" >&2
    exit 1
  fi

  echo "docs-only changed files check passed."
}

validate_workflow_yaml() {
  local workflow_count=0
  local workflow

  # PR1에서는 workflow를 바꾸지 않지만, ci profile을 로컬에서 확인할 수 있게 syntax만 봅니다.
  # macOS 기본 Ruby YAML parser로 충분해서 dependency를 새로 넣지 않습니다.
  while IFS= read -r workflow; do
    workflow_count=$((workflow_count + 1))
    ruby --disable-gems -e 'require "yaml"; YAML.load_file(ARGV[0])' "$workflow"
  done < <(find .github/workflows -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)

  if ((workflow_count == 0)); then
    echo "No GitHub workflow files found." >&2
    exit 1
  fi

  echo "GitHub workflow YAML syntax check passed."
}

prepare_tuist_workspace() {
  # GitHub fresh runner에는 생성물이 없으므로 build profile에서는 install/generate를 먼저 돌립니다.
  # 재사용 신호는 이 함수가 성공한 뒤 child process에만 넘깁니다.
  echo "Preparing Tuist workspace..."
  mise exec -- tuist install
  mise exec -- tuist generate
}

plan_for_profile() {
  # profile은 검증 방식과 비용을 정하고, scheme 입력은 검증 대상을 정합니다.
  # 새 module을 추가하면 validate_ios_module.sh whitelist와 필요한 docs를 같이 바꿉니다.
  case "$PROFILE" in
    project-setup)
      # Tuist helper나 manifest 규칙을 건드렸을 때 쓰는 넓은 profile입니다.
      # 전체 앱 test 대신 AppMain과 현재 공개된 module scheme이 build되는지만 봅니다.
      add_script_step "Static Tuist policy" "$ROOT_DIR/scripts/validate_tuist_foundation.sh"
      add_build_step "AppMain baseline" "$ROOT_DIR/scripts/validate_ios_baseline.sh"
      add_project_setup_module_steps
      ;;
    ci)
      # GitHub label mapping을 붙이기 전까지는 로컬에서 직접 호출하는 CI 성격의 profile입니다.
      add_script_step "Static Tuist policy" "$ROOT_DIR/scripts/validate_tuist_foundation.sh"
      add_function_step "GitHub workflow YAML syntax" validate_workflow_yaml
      add_build_step "AppMain baseline" "$ROOT_DIR/scripts/validate_ios_baseline.sh"
      ;;
    app-main)
      # 앱 진입점이나 공통 wiring만 바뀐 경우 AppMain scheme만 확인합니다.
      add_build_step "AppMain baseline" "$ROOT_DIR/scripts/validate_ios_baseline.sh"
      ;;
    tuist-foundation)
      # Tuist manifest 규칙과 generated artifact만 빠르게 보고 싶을 때 씁니다.
      add_script_step "Static Tuist policy" "$ROOT_DIR/scripts/validate_tuist_foundation.sh"
      ;;
    module)
      # 지정한 module scheme만 확인합니다. AppMain 조립까지 볼 필요가 없을 때 씁니다.
      add_module_steps
      ;;
    integration)
      # 지정한 module scheme과 AppMain 조립을 같이 봅니다.
      add_module_steps
      add_build_step "AppMain baseline" "$ROOT_DIR/scripts/validate_ios_baseline.sh"
      ;;
    docs-only)
      # docs-only는 build를 생략하는 대신 changed files로 코드 변경이 섞였는지 확인합니다.
      add_function_step "Docs-only changed files check" validate_docs_only_changed_files
      add_script_step "Tracked generated artifact preflight" "$ROOT_DIR/scripts/validate_tuist_foundation.sh" "--generated-artifacts-only"
      ;;
    *)
      echo "Unknown CLIPY_IOS_VALIDATION_PROFILE: ${PROFILE}" >&2
      usage
      exit 2
      ;;
  esac
}

print_plan() {
  local arg1
  local arg2
  local command
  local description
  local index
  local kind

  # dry-run도 실제 실행과 같은 PLAN을 봅니다.
  # 그래서 build 없이도 어떤 검증이 돌지 먼저 리뷰할 수 있습니다.
  echo "Validation profile: ${PROFILE}"
  echo "Validation mode: ${CLIPY_IOS_VALIDATION_MODE}"
  if plan_has_build_step; then
    echo "Tuist prep: once before the first build step"
  else
    echo "Tuist prep: not needed"
  fi
  echo "Validation plan:"
  for index in "${!PLAN[@]}"; do
    IFS='|' read -r kind description command arg1 arg2 <<< "${PLAN[$index]}"
    if [[ "$kind" == "script" || "$kind" == "build-script" ]]; then
      command="$(format_command "$command" ${arg1:+"$arg1"} ${arg2:+"$arg2"})"
    fi
    printf '  %d. %s: %s\n' "$((index + 1))" "$description" "$command"
  done
}

plan_has_build_step() {
  local index
  local kind

  # build step이 하나라도 있으면 Tuist install/generate가 필요합니다.
  # docs-only처럼 function/script step만 있으면 workspace를 만들지 않습니다.
  for index in "${!PLAN[@]}"; do
    IFS='|' read -r kind _ <<< "${PLAN[$index]}"
    if [[ "$kind" == "build-script" ]]; then
      return 0
    fi
  done

  return 1
}

execute_plan() {
  local arg1
  local arg2
  local description
  local index
  local kind
  local command
  local tuist_prepared="0"

  # PLAN 순서대로 실행하되, 첫 build-script 직전에만 Tuist workspace를 만듭니다.
  # static policy가 실패하면 generate 비용을 쓰기 전에 멈춥니다.
  for index in "${!PLAN[@]}"; do
    IFS='|' read -r kind description command arg1 arg2 <<< "${PLAN[$index]}"
    echo "==> ${description}"
    if [[ "$kind" == "function" ]]; then
      # function step은 현재 shell 함수로 실행합니다. docs-only나 yaml syntax처럼 별도 script가 필요 없는 검증입니다.
      "$command"
    else
      if [[ "$kind" == "build-script" && "$tuist_prepared" != "1" ]]; then
        prepare_tuist_workspace
        # 이 flag는 방금 만든 workspace를 하위 검증에서만 다시 쓰게 하는 내부 신호입니다.
        export CLIPY_IOS_SKIP_TUIST_PREP=1
        tuist_prepared="1"
      fi
      run_command "$command" ${arg1:+"$arg1"} ${arg2:+"$arg2"}
    fi
  done
}

plan_for_profile
print_plan

if [[ "$DRY_RUN" == "1" ]]; then
  exit 0
fi

execute_plan
