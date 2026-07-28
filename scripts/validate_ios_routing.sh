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

assert_occurrences() {
  local output="$1"
  local expected="$2"
  local count="$3"
  local scenario="$4"
  local actual

  actual="$(grep -Fc "$expected" <<< "$output" || true)"
  if [[ "$actual" != "$count" ]]; then
    echo "${scenario}: expected '${expected}' ${count} time(s), found ${actual}" >&2
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

resolve_requirements() {
  CLIPY_IOS_LABEL_ROUTER_DRY_RUN=1 \
  CLIPY_IOS_PR_LABELS="$1" \
  CLIPY_IOS_CHANGED_FILES="${2:-}" \
  CLIPY_IOS_CHANGED_FILES_FILE= \
    "$ROOT_DIR/scripts/resolve_ios_validation_from_labels.sh" 2>/dev/null
}

resolve_nul_changed_files() {
  local changed_files_path="/tmp/clipy-nul-changed-files-$$"
  local output

  printf '%s\0' \
    "Modules/CoreDesignSystem/Sources/아이콘.swift" \
    "Modules/FeatureHome/Sources/아이콘.swift" \
    > "$changed_files_path"

  output="$(
    CLIPY_IOS_PR_LABELS=$'TYPE | Feature\nAREA | Docs' \
    CLIPY_IOS_CHANGED_FILES= \
    CLIPY_IOS_CHANGED_FILES_FILE="$changed_files_path" \
    CLIPY_IOS_CHANGED_FILES_FORMAT=nul \
      "$ROOT_DIR/scripts/resolve_ios_validation_from_labels.sh"
  )"
  rm -f "$changed_files_path"
  printf '%s\n' "$output"
}

assert_resolve_fails() {
  local labels="$1"
  local changed_files="$2"
  local expected="$3"
  local scenario="$4"
  local output

  if output="$(
    CLIPY_IOS_LABEL_ROUTER_DRY_RUN=1 \
    CLIPY_IOS_PR_LABELS="$labels" \
    CLIPY_IOS_CHANGED_FILES="$changed_files" \
    CLIPY_IOS_CHANGED_FILES_FILE= \
      "$ROOT_DIR/scripts/resolve_ios_validation_from_labels.sh" 2>&1
  )"; then
    echo "${scenario}: expected resolution to fail" >&2
    echo "$output" >&2
    failures=$((failures + 1))
    return
  fi

  assert_contains "$output" "$expected" "$scenario"
}

assert_missing_changed_file_fails() {
  local output
  local missing_file="/tmp/clipy-missing-changed-files-$$"

  if output="$(
    CLIPY_IOS_PR_LABELS=$'TYPE | Chore\nAREA | CI' \
    CLIPY_IOS_CHANGED_FILES= \
    CLIPY_IOS_CHANGED_FILES_FILE="$missing_file" \
      "$ROOT_DIR/scripts/resolve_ios_validation_from_labels.sh" 2>&1
  )"; then
    echo "Missing changed-files input: expected resolution to fail" >&2
    echo "$output" >&2
    failures=$((failures + 1))
    return
  fi

  assert_contains "$output" "CLIPY_IOS_CHANGED_FILES_FILE does not exist" "Missing changed-files input"
}

assert_missing_event_file_fails() {
  local output
  local missing_file="/tmp/clipy-missing-event-$$.json"

  if output="$(
    CLIPY_IOS_PR_LABELS= \
    GITHUB_EVENT_PATH="$missing_file" \
    CLIPY_IOS_CHANGED_FILES= \
    CLIPY_IOS_CHANGED_FILES_FILE= \
      "$ROOT_DIR/scripts/resolve_ios_validation_from_labels.sh" 2>&1
  )"; then
    echo "Missing event input: expected resolution to fail" >&2
    echo "$output" >&2
    failures=$((failures + 1))
    return
  fi

  assert_contains "$output" "GITHUB_EVENT_PATH does not exist" "Missing event input"
}

assert_capability_plan_fails() {
  local capabilities="$1"
  local expected="$2"
  local scenario="$3"
  local output

  if output="$(
    CLIPY_IOS_VALIDATION_PROFILE=capabilities \
    CLIPY_IOS_VALIDATION_CAPABILITIES="$capabilities" \
    CLIPY_IOS_VALIDATION_DRY_RUN=1 \
      "$ROOT_DIR/scripts/validate_ios_profile.sh" 2>&1
  )"; then
    echo "${scenario}: expected capability planning to fail" >&2
    echo "$output" >&2
    failures=$((failures + 1))
    return
  fi

  assert_contains "$output" "$expected" "$scenario"
}

assert_missing_changed_file_fails
assert_missing_event_file_fails
assert_capability_plan_fails \
  "module:AppMain:test" \
  "Unsupported module validation scheme in capability" \
  "AppMain test capability rejection"
assert_capability_plan_fails \
  "module:AppMain:build" \
  "Unsupported module validation scheme in capability" \
  "AppMain build capability rejection"

ui_system_output="$(resolve_requirements $'TYPE | Feature\nAREA | UI System')"
assert_exact_line "$ui_system_output" "CLIPY_IOS_VALIDATION_PROFILE=capabilities" "UI System routing"
assert_exact_line "$ui_system_output" "CLIPY_IOS_VALIDATION_CAPABILITIES=module:CoreDesignSystem:test" "UI System routing"

feature_home_output="$(resolve_requirements $'TYPE | Feature\nAREA | FeatureHome')"
assert_exact_line "$feature_home_output" "CLIPY_IOS_VALIDATION_CAPABILITIES=module:FeatureHome:build" "FeatureHome routing"

ci_only_output="$(resolve_requirements $'TYPE | Chore\nAREA | CI')"
assert_exact_line "$ci_only_output" "CLIPY_IOS_VALIDATION_CAPABILITIES=ci" "CI-only routing"

ci_multi_output="$(
  resolve_requirements $'TYPE | Chore\nAREA | CI\nAREA | UI System\nAREA | FeatureHome'
)"
assert_exact_line \
  "$ci_multi_output" \
  "CLIPY_IOS_VALIDATION_CAPABILITIES=ci module:CoreDesignSystem:test module:FeatureHome:build" \
  "CI + multiple AREA union"

feature_docs_output="$(resolve_requirements $'TYPE | Feature\nAREA | Docs\nAREA | CoreDomain')"
assert_exact_line "$feature_docs_output" "CLIPY_IOS_VALIDATION_CAPABILITIES=module:CoreDomain:build" "Docs is inert in a code union"

feature_docs_only_output="$(
  resolve_requirements $'TYPE | Feature\nAREA | Docs' $'Docs/Open/SETUP.md\nREADME.md'
)"
assert_exact_line "$feature_docs_only_output" "CLIPY_IOS_VALIDATION_CAPABILITIES=docs" "Docs-only routing"

nul_rename_output="$(resolve_nul_changed_files)"
assert_exact_line \
  "$nul_rename_output" \
  "CLIPY_IOS_VALIDATION_CAPABILITIES=module:CoreDesignSystem:test module:FeatureHome:build" \
  "NUL rename source and destination routing"

changed_file_union_output="$(
  resolve_requirements \
    $'TYPE | Feature\nAREA | Docs\nAREA | CI\nAREA | Project Setup\nAREA | CoreDomain' \
    $'.swiftlint.yml\nModules/CoreDesignSystem/Sources/Font.swift\nModules/FeatureHome/Sources/HomeView.swift\nDocs/Open/SETUP.md'
)"
assert_exact_line \
  "$changed_file_union_output" \
  "CLIPY_IOS_VALIDATION_CAPABILITIES=ci project-setup swiftlint-config module:CoreDomain:build module:CoreDesignSystem:test module:FeatureHome:build" \
  "Label and changed-file capability union"

path_can_widen_labels_output="$(
  resolve_requirements $'TYPE | Feature\nAREA | Docs' 'Modules/FeatureSession/Sources/FeatureSession.swift'
)"
assert_exact_line \
  "$path_can_widen_labels_output" \
  "CLIPY_IOS_VALIDATION_CAPABILITIES=module:FeatureSession:build" \
  "Changed path widens an incomplete AREA selection"

assert_resolve_fails \
  $'TYPE | Docs\nAREA | Docs' \
  'Modules/FeatureHome/Sources/HomeView.swift' \
  "TYPE | Docs cannot describe code" \
  "Docs type with code path"

assert_resolve_fails \
  $'TYPE | Chore\nAREA | CI' \
  'config/unmapped.yml' \
  "No iOS validation capability mapping found for changed path" \
  "Unknown changed path"

capability_union_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=capabilities \
  CLIPY_IOS_VALIDATION_CAPABILITIES='ci project-setup module:CoreDesignSystem:test module:CoreDesignSystem:test' \
  CLIPY_IOS_CHANGED_FILES=$'.github/workflows/ios-baseline.yml\nModules/CoreDesignSystem/Sources/Font.swift' \
  CLIPY_IOS_VALIDATION_MODE=build-for-testing \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_contains "$capability_union_plan" "Static Tuist policy" "Capability union plan"
assert_contains "$capability_union_plan" "iOS validation routing contract" "Capability union plan"
assert_contains "$capability_union_plan" "GitHub workflow YAML syntax" "Capability union plan"
assert_contains "$capability_union_plan" "Module CoreDomain" "Project Setup expansion"
assert_contains "$capability_union_plan" "Module CorePersistence" "Project Setup expansion"
assert_contains "$capability_union_plan" "Module FeatureHome" "Project Setup expansion"
assert_contains "$capability_union_plan" "Module FeatureSession" "Project Setup expansion"
assert_contains "$capability_union_plan" "Module CoreDesignSystem contract test" "Test dominates build"
assert_contains "$capability_union_plan" "CLIPY_IOS_VALIDATION_MODE=test" "Test dominates build"
assert_occurrences "$capability_union_plan" "validate_ios_module.sh CoreDesignSystem" "1" "Duplicate capability removal"
assert_contains "$capability_union_plan" "AppMain baseline" "Capability union plan"

reversed_dominance_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=capabilities \
  CLIPY_IOS_VALIDATION_CAPABILITIES='module:CoreDesignSystem:test project-setup' \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_contains "$reversed_dominance_plan" "Module CoreDesignSystem contract test" "Order-independent test dominance"
assert_occurrences \
  "$reversed_dominance_plan" \
  "validate_ios_module.sh CoreDesignSystem" \
  "1" \
  "Order-independent test dominance"

swiftlint_config_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=capabilities \
  CLIPY_IOS_VALIDATION_CAPABILITIES='swiftlint-config swiftlint-config' \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_occurrences \
  "$swiftlint_config_plan" \
  "SwiftLint configuration YAML:" \
  "1" \
  "Duplicate SwiftLint config capability removal"
assert_contains "$swiftlint_config_plan" "validate_swiftlint_config" "SwiftLint config capability plan"
assert_not_contains "$swiftlint_config_plan" "AppMain baseline" "SwiftLint config-only plan"

docs_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=capabilities \
  CLIPY_IOS_VALIDATION_CAPABILITIES='docs docs' \
  CLIPY_IOS_CHANGED_FILES='Docs/Open/SETUP.md' \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_occurrences "$docs_plan" "Docs-only changed files check" "1" "Docs capability dedupe"
assert_contains "$docs_plan" "Tracked generated artifact preflight" "Docs capability plan"
assert_not_contains "$docs_plan" "AppMain baseline" "Docs capability plan"

integration_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=integration \
  CLIPY_IOS_VALIDATION_SCHEMES=CoreDesignSystem \
  CLIPY_IOS_VALIDATION_MODE=build-for-testing \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_contains "$integration_plan" "Module CoreDesignSystem contract test" "Manual integration contract test"
assert_contains "$integration_plan" "AppMain baseline" "Manual integration AppMain build"

project_setup_plan="$(
  CLIPY_IOS_VALIDATION_PROFILE=project-setup \
  CLIPY_IOS_VALIDATION_MODE=build-for-testing \
  CLIPY_IOS_VALIDATION_DRY_RUN=1 \
    "$ROOT_DIR/scripts/validate_ios_profile.sh"
)"
assert_contains "$project_setup_plan" "Module CoreDesignSystem" "Manual Project Setup build"
assert_not_contains "$project_setup_plan" "Module CoreDesignSystem contract test" "Manual Project Setup build-only boundary"

workflow_file="$ROOT_DIR/.github/workflows/ios-baseline.yml"
assert_file_contains \
  "$workflow_file" \
  'run: ./scripts/resolve_ios_validation_from_labels.sh >> "$GITHUB_ENV"' \
  "GitHub Actions resolver env handoff"
assert_file_contains \
  "$workflow_file" \
  'run: ./scripts/validate_ios_profile.sh' \
  "GitHub Actions profile consumer"
assert_file_contains \
  "$workflow_file" \
  'git diff --no-renames --name-only -z' \
  "GitHub Actions raw rename path collection"
assert_file_contains \
  "$workflow_file" \
  'CLIPY_IOS_CHANGED_FILES_FORMAT=nul' \
  "GitHub Actions NUL path format handoff"

if ((failures > 0)); then
  echo "iOS validation routing contract failed with ${failures} issue(s)." >&2
  exit 1
fi

echo "iOS validation routing contract passed."
