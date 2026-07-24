#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROFILE="${CLIPY_IOS_VALIDATION_PROFILE:-}"
SCHEMES_RAW="${CLIPY_IOS_VALIDATION_SCHEMES:-}"
DRY_RUN="${CLIPY_IOS_VALIDATION_DRY_RUN:-0}"
# 기본값은 simulator를 띄우지 않는 build-for-testing입니다. test mode는 필요한 작업에서만 명시합니다.
export CLIPY_IOS_VALIDATION_MODE="${CLIPY_IOS_VALIDATION_MODE:-build-for-testing}"

# 이 script는 label resolver나 로컬 호출자가 넘긴 profile을 실제 검증 순서로 바꿉니다.
# dry-run과 실제 실행이 같은 PLAN을 보므로 CI에서 고른 흐름을 로컬에서도 재현합니다.
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
  CLIPY_IOS_XCODEBUILD_CONFIGURATION optional xcodebuild configuration, such as Release
USAGE
}

if [[ -z "$PROFILE" ]]; then
  # profile이 없으면 fail-fast로 멈춥니다.
  # 여기서 넓은 검증으로 추정하면 CI 비용과 실제 검증 범위가 호출자마다 달라집니다.
  echo "CLIPY_IOS_VALIDATION_PROFILE is required." >&2
  usage
  exit 2
fi

# dry-run이어도 mode 오타는 먼저 잡습니다. 잘못된 plan이 PR이나 CI 설정에 남으면 재현이 어렵습니다.
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
  "CoreDesignSystem"
  "FeatureSession"
)
RUNTIME_CONTRACT_TEST_SCHEMES=(
  "CoreDesignSystem"
)

# PLAN 배열은 dry-run과 실제 실행이 함께 쓰는 command 목록입니다.
# 입력을 어떻게 받았든 최종 검증 순서는 이 배열만 봅니다.
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

# build가 처음 필요해질 때만 Tuist workspace를 만들고, 같은 profile 안에서는 재사용합니다.
# module이 여러 개여도 install/generate를 반복하지 않게 하는 비용 절감 경계입니다.
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

# 특정 module step만 runtime contract test로 올릴 때 씁니다.
# profile 전체 mode는 그대로 두어 AppMain과 다른 module의 build-only 비용을 유지합니다.
add_build_step_with_mode() {
  local description="$1"
  local mode="$2"
  local command="$3"
  local arg1="${4:-}"
  local arg2="${5:-}"

  PLAN+=("build-script-mode|${description}|${command}|${arg1}|${arg2}|${mode}")
}

add_function_step() {
  local description="$1"
  local function_name="$2"

  PLAN+=("function|${description}|${function_name}")
}

run_command() {
  # CI 로그에서 실제로 실행한 command를 바로 찾을 수 있게 먼저 찍습니다.
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

  # scheme 오타는 Tuist generate 전에 잡고, 실제 build는 plan step에서 다시 실행합니다.
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

requires_runtime_contract_test() {
  local candidate="$1"
  local scheme

  for scheme in "${RUNTIME_CONTRACT_TEST_SCHEMES[@]}"; do
    if [[ "$scheme" == "$candidate" ]]; then
      return 0
    fi
  done

  return 1
}

add_module_steps() {
  local scheme

  require_validation_schemes

  for scheme in "${VALIDATION_SCHEMES[@]}"; do
    if requires_runtime_contract_test "$scheme" && [[ "$CLIPY_IOS_VALIDATION_MODE" == "build-for-testing" ]]; then
      # compile만으로 확인할 수 없는 runtime contract가 있는 module만 정책 목록에 두고 simulator test로 올립니다.
      add_build_step_with_mode \
        "Module ${scheme} contract test" \
        "test" \
        "$ROOT_DIR/scripts/validate_ios_module.sh" \
        "$scheme"
    else
      add_build_step "Module ${scheme}" "$ROOT_DIR/scripts/validate_ios_module.sh" "$scheme"
    fi
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
  # GitHub에서는 workflow가, 로컬에서는 사람이 changed files를 넘깁니다.
  # 여기서는 출처를 따지지 않고 docs-only로 build를 생략해도 되는지만 검사합니다.
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

  # docs-only는 문서와 GitHub template 변경만 허용합니다.
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
  # build를 생략하는 profile이라서, 증거가 없을 때 안전한 쪽으로 실패시킵니다.
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
    # docs-only로 돌렸지만 코드성 파일이 섞였으므로 더 넓은 profile로 다시 봐야 합니다.
    echo "docs-only profile received non-doc/template paths:" >&2
    printf '  %s\n' "${invalid_paths[@]}" >&2
    exit 1
  fi

  echo "docs-only changed files check passed."
}

validate_workflow_yaml() {
  local workflow_count=0
  local workflow

  # workflow 변경은 먼저 YAML 문법만 봅니다. macOS 기본 Ruby parser로 충분해서 dependency를 늘리지 않습니다.
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
  # GitHub runner에는 생성물이 없으므로 build profile에서는 install/generate를 먼저 돌립니다.
  # 재사용 flag는 이 함수가 성공한 뒤 같은 profile의 하위 script에만 넘깁니다.
  # 로컬에서 오래된 workspace를 재사용하는 용도로 쓰지 않습니다.
  echo "Preparing Tuist workspace..."
  mise exec -- tuist install
  mise exec -- tuist generate
}

plan_for_profile() {
  # profile은 검증 비용과 조합을 정하고, scheme 입력은 실제 대상을 정합니다.
  # 새 module은 허용 scheme 목록과 label resolver까지 맞춘 뒤 profile에 넣습니다.
  case "$PROFILE" in
    project-setup)
      # Tuist helper나 manifest 규칙을 건드렸을 때는 module build까지 넓게 봅니다.
      add_script_step "Static Tuist policy" "$ROOT_DIR/scripts/validate_tuist_foundation.sh"
      add_build_step "AppMain baseline" "$ROOT_DIR/scripts/validate_ios_baseline.sh"
      add_project_setup_module_steps
      ;;
    ci)
      # GitHub Actions나 validation script 변경은 YAML과 AppMain 조립을 보고, 검증 scheme이 연결된 AREA가 있으면 해당 scheme도 같이 봅니다.
      add_script_step "Static Tuist policy" "$ROOT_DIR/scripts/validate_tuist_foundation.sh"
      add_script_step "iOS validation routing contract" "$ROOT_DIR/scripts/validate_ios_routing.sh"
      add_function_step "GitHub workflow YAML syntax" validate_workflow_yaml
      if [[ -n "$SCHEMES_RAW" ]]; then
        add_module_steps
      fi
      add_build_step "AppMain baseline" "$ROOT_DIR/scripts/validate_ios_baseline.sh"
      ;;
    app-main)
      # 앱 진입점이나 공통 wiring만 바뀐 경우 AppMain scheme만 봅니다.
      add_build_step "AppMain baseline" "$ROOT_DIR/scripts/validate_ios_baseline.sh"
      ;;
    tuist-foundation)
      # Tuist manifest 규칙과 git에 이미 올라간 생성물만 빠르게 봅니다.
      add_script_step "Static Tuist policy" "$ROOT_DIR/scripts/validate_tuist_foundation.sh"
      ;;
    module)
      # 지정한 module scheme만 봅니다. AppMain 조립까지 필요하면 integration을 씁니다.
      add_module_steps
      ;;
    integration)
      # module 변경이 앱 조립에서 깨지는지 같이 봅니다.
      add_module_steps
      add_build_step "AppMain baseline" "$ROOT_DIR/scripts/validate_ios_baseline.sh"
      ;;
    docs-only)
      # docs-only는 build를 생략하므로 changed files가 문서와 GitHub template 범위인지 먼저 봅니다.
      # 코드성 파일이 하나라도 섞이면 이 profile을 쓰지 않습니다.
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
  local step_mode

  # dry-run도 같은 PLAN을 보므로 build 없이 실제 검증 순서를 확인할 수 있습니다.
  echo "Validation profile: ${PROFILE}"
  echo "Validation mode: ${CLIPY_IOS_VALIDATION_MODE}"
  if plan_has_build_step; then
    echo "Tuist prep: once before the first build step"
  else
    echo "Tuist prep: not needed"
  fi
  echo "Validation plan:"
  for index in "${!PLAN[@]}"; do
    IFS='|' read -r kind description command arg1 arg2 step_mode <<< "${PLAN[$index]}"
    if [[ "$kind" == "script" || "$kind" == "build-script" || "$kind" == "build-script-mode" ]]; then
      command="$(format_command "$command" ${arg1:+"$arg1"} ${arg2:+"$arg2"})"
      if [[ "$kind" == "build-script-mode" ]]; then
        command="CLIPY_IOS_VALIDATION_MODE=$(printf '%q' "$step_mode") ${command}"
      fi
    fi
    printf '  %d. %s: %s\n' "$((index + 1))" "$description" "$command"
  done
}

plan_has_build_step() {
  local index
  local kind

  # build step이 없으면 workspace를 만들지 않습니다.
  # docs-only처럼 build를 생략하는 profile에서 Tuist 비용을 쓰지 않기 위해서입니다.
  for index in "${!PLAN[@]}"; do
    IFS='|' read -r kind _ <<< "${PLAN[$index]}"
    if [[ "$kind" == "build-script" || "$kind" == "build-script-mode" ]]; then
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
  local step_mode
  local tuist_prepared="0"

  # 정적 정책 검사가 실패하면 generate 비용을 쓰기 전에 멈춥니다.
  # 첫 build-script 직전에만 workspace를 만들고 이후 build step은 같은 profile 안에서 재사용합니다.
  for index in "${!PLAN[@]}"; do
    IFS='|' read -r kind description command arg1 arg2 step_mode <<< "${PLAN[$index]}"
    echo "==> ${description}"
    if [[ "$kind" == "function" ]]; then
      # function step은 docs-only나 YAML syntax처럼 별도 script가 필요 없는 검사만 둡니다.
      "$command"
    else
      if [[ ("$kind" == "build-script" || "$kind" == "build-script-mode") && "$tuist_prepared" != "1" ]]; then
        prepare_tuist_workspace
        # 방금 만든 workspace를 같은 profile 안에서만 재사용하게 하는 내부 신호입니다.
        export CLIPY_IOS_SKIP_TUIST_PREP=1
        tuist_prepared="1"
      fi
      if [[ "$kind" == "build-script-mode" ]]; then
        echo "+ CLIPY_IOS_VALIDATION_MODE=$(printf '%q' "$step_mode") $(format_command "$command" ${arg1:+"$arg1"} ${arg2:+"$arg2"})"
        CLIPY_IOS_VALIDATION_MODE="$step_mode" \
          "$command" ${arg1:+"$arg1"} ${arg2:+"$arg2"}
      else
        run_command "$command" ${arg1:+"$arg1"} ${arg2:+"$arg2"}
      fi
    fi
  done
}

plan_for_profile
print_plan

if [[ "$DRY_RUN" == "1" ]]; then
  exit 0
fi

execute_plan
