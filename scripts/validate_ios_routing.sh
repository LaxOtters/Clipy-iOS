#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

failures=0

assert_contains() {
  local output="$1"
  local expected="$2"
  local scenario="$3"

  if [[ "$output" != *"$expected"* ]]; then
    echo "${scenario}: expected '${expected}'" >&2
    echo "$output" >&2
    failures=$((failures + 1))
  fi
}

assert_not_contains() {
  local output="$1"
  local unexpected="$2"
  local scenario="$3"

  if [[ "$output" == *"$unexpected"* ]]; then
    echo "${scenario}: did not expect '${unexpected}'" >&2
    echo "$output" >&2
    failures=$((failures + 1))
  fi
}

assert_exact_line() {
  local output="$1"
  local expected="$2"
  local scenario="$3"

  if ! grep -Fqx "$expected" <<< "$output"; then
    echo "${scenario}: expected exact line '${expected}'" >&2
    echo "$output" >&2
    failures=$((failures + 1))
  fi
}

assert_file_contains() {
  local file="$1"
  local expected="$2"
  local scenario="$3"

  if ! grep -Fq "$expected" "$file"; then
    echo "${scenario}: expected '${expected}' in ${file}" >&2
    failures=$((failures + 1))
  fi
}

resolve_labels() {
  CLIPY_IOS_LABEL_ROUTER_DRY_RUN=1 \
  CLIPY_IOS_PR_LABELS="$1" \
    "$ROOT_DIR/scripts/resolve_ios_validation_from_labels.sh" 2>/dev/null
}

ui_system_output="$(resolve_labels $'TYPE | Feature\nAREA | UI System')"
assert_contains "$ui_system_output" "CLIPY_IOS_VALIDATION_PROFILE=integration" "UI System routing"
assert_contains "$ui_system_output" "CLIPY_IOS_VALIDATION_SCHEMES=CoreDesignSystem" "UI System routing"

ci_only_output="$(resolve_labels $'TYPE | Chore\nAREA | CI')"
assert_contains "$ci_only_output" "CLIPY_IOS_VALIDATION_PROFILE=ci" "CI-only routing"
assert_exact_line "$ci_only_output" "CLIPY_IOS_VALIDATION_SCHEMES=" "CI-only routing"

ci_app_main_output="$(resolve_labels $'TYPE | Chore\nAREA | CI\nAREA | AppMain')"
assert_contains "$ci_app_main_output" "CLIPY_IOS_VALIDATION_PROFILE=ci" "CI + AppMain routing"
assert_exact_line "$ci_app_main_output" "CLIPY_IOS_VALIDATION_SCHEMES=" "CI + AppMain routing"

ci_ui_system_output="$(resolve_labels $'TYPE | Chore\nAREA | CI\nAREA | UI System')"
assert_contains "$ci_ui_system_output" "CLIPY_IOS_VALIDATION_PROFILE=ci" "CI + UI System routing"
assert_contains "$ci_ui_system_output" "CLIPY_IOS_VALIDATION_SCHEMES=CoreDesignSystem" "CI + UI System routing"

ci_multi_module_output="$(resolve_labels $'TYPE | Chore\nAREA | CI\nAREA | CoreDomain\nAREA | FeatureSession')"
assert_contains "$ci_multi_module_output" "CLIPY_IOS_VALIDATION_PROFILE=ci" "CI + multiple module routing"
assert_contains "$ci_multi_module_output" "CLIPY_IOS_VALIDATION_SCHEMES=CoreDomain FeatureSession" "CI + multiple module routing"

ci_core_persistence_output="$(resolve_labels $'TYPE | Chore\nAREA | CI\nAREA | CorePersistence')"
assert_contains "$ci_core_persistence_output" "CLIPY_IOS_VALIDATION_PROFILE=ci" "CI + CorePersistence routing"
assert_contains "$ci_core_persistence_output" "CLIPY_IOS_VALIDATION_SCHEMES=CorePersistence" "CI + CorePersistence routing"

ci_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=ci \
  CLIPY_IOS_VALIDATION_SCHEMES=CoreDesignSystem \
  CLIPY_IOS_VALIDATION_MODE=build-for-testing \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_contains "$ci_plan" "Module CoreDesignSystem" "CI + CoreDesignSystem plan"
assert_contains "$ci_plan" "CLIPY_IOS_VALIDATION_MODE=test" "CI + CoreDesignSystem contract test mode"
assert_contains "$ci_plan" "validate_ios_module.sh CoreDesignSystem" "CI + CoreDesignSystem contract test command"
assert_contains "$ci_plan" "AppMain baseline" "CI + CoreDesignSystem plan"

integration_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=integration \
  CLIPY_IOS_VALIDATION_SCHEMES=CoreDesignSystem \
  CLIPY_IOS_VALIDATION_MODE=build-for-testing \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_contains "$integration_plan" "Module CoreDesignSystem contract test" "CoreDesignSystem integration contract test"
assert_contains "$integration_plan" "CLIPY_IOS_VALIDATION_MODE=test" "CoreDesignSystem integration contract test mode"
assert_contains "$integration_plan" "AppMain baseline" "CoreDesignSystem integration AppMain build"

core_design_system_build_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=integration \
  CLIPY_IOS_VALIDATION_SCHEMES=CoreDesignSystem \
  CLIPY_IOS_VALIDATION_MODE=build \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_contains "$core_design_system_build_plan" "Module CoreDesignSystem" "CoreDesignSystem explicit build mode"
assert_not_contains "$core_design_system_build_plan" "CLIPY_IOS_VALIDATION_MODE=test" "CoreDesignSystem explicit build mode"

core_design_system_test_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=integration \
  CLIPY_IOS_VALIDATION_SCHEMES=CoreDesignSystem \
  CLIPY_IOS_VALIDATION_MODE=test \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_contains "$core_design_system_test_plan" "Validation mode: test" "CoreDesignSystem explicit test mode"
assert_contains "$core_design_system_test_plan" "Module CoreDesignSystem" "CoreDesignSystem explicit test mode"

project_setup_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=project-setup \
  CLIPY_IOS_VALIDATION_MODE=build-for-testing \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_contains "$project_setup_plan" "Module CoreDesignSystem" "Project setup CoreDesignSystem build"
assert_not_contains "$project_setup_plan" "Module CoreDesignSystem contract test" "Project setup build-only boundary"
assert_not_contains "$project_setup_plan" "CLIPY_IOS_VALIDATION_MODE=test" "Project setup build-only boundary"

ci_only_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=ci \
  CLIPY_IOS_VALIDATION_SCHEMES="" \
  CLIPY_IOS_VALIDATION_MODE=build-for-testing \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_contains "$ci_only_plan" "AppMain baseline" "CI-only plan"
assert_not_contains "$ci_only_plan" "Module " "CI-only plan"

workflow_file="$ROOT_DIR/.github/workflows/ios-baseline.yml"
assert_file_contains \
  "$workflow_file" \
  'run: ./scripts/resolve_ios_validation_from_labels.sh >> "$GITHUB_ENV"' \
  "GitHub Actions resolver env handoff"
assert_file_contains \
  "$workflow_file" \
  'run: ./scripts/validate_ios_profile.sh' \
  "GitHub Actions profile consumer"

if ((failures > 0)); then
  echo "iOS validation routing contract failed with ${failures} issue(s)." >&2
  exit 1
fi

echo "iOS validation routing contract passed."
