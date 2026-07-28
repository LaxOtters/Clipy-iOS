#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

LABELS_RAW="${CLIPY_IOS_PR_LABELS:-}"
CHANGED_FILES_FORMAT="${CLIPY_IOS_CHANGED_FILES_FORMAT:-lines}"
DRY_RUN="${CLIPY_IOS_LABEL_ROUTER_DRY_RUN:-0}"

usage() {
  cat >&2 <<USAGE
Usage: CLIPY_IOS_PR_LABELS=<newline-separated labels> $0

Inputs:
  CLIPY_IOS_PR_LABELS             optional newline-separated GitHub PR label names
  GITHUB_EVENT_PATH               optional GitHub pull_request event payload path
  CLIPY_IOS_CHANGED_FILES         optional newline-separated changed file paths
  CLIPY_IOS_CHANGED_FILES_FILE    optional file containing changed file paths
  CLIPY_IOS_CHANGED_FILES_FORMAT  lines | nul for file input (default: lines)
  CLIPY_IOS_LABEL_ROUTER_DRY_RUN  set to 1 to log the resolved inputs to stderr

Output:
  CLIPY_IOS_VALIDATION_PROFILE=capabilities
  CLIPY_IOS_VALIDATION_CAPABILITIES=<space-separated capabilities>
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
  if [[ ! -r "$event_path" ]]; then
    echo "GITHUB_EVENT_PATH is not readable: ${event_path}" >&2
    exit 2
  fi

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
    "AREA | Docs"|"AREA | Project Setup"|"AREA | CI"|"AREA | AppMain"|"AREA | CoreDomain"|"AREA | CorePersistence"|"AREA | UI System"|"AREA | FeatureHome"|"AREA | FeatureSession")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

contains_capability() {
  local candidate="$1"
  shift
  local capability

  for capability in "$@"; do
    if [[ "$capability" == "$candidate" ]]; then
      return 0
    fi
  done

  return 1
}

add_capability() {
  local capability="$1"

  if ((${#CAPABILITIES[@]} > 0)) && contains_capability "$capability" "${CAPABILITIES[@]}"; then
    return
  fi

  CAPABILITIES+=("$capability")
}

add_capability_for_area() {
  case "$1" in
    "AREA | Docs")
      add_capability "docs"
      ;;
    "AREA | Project Setup")
      add_capability "project-setup"
      ;;
    "AREA | CI")
      add_capability "ci"
      ;;
    "AREA | AppMain")
      add_capability "app-main"
      ;;
    "AREA | CoreDomain")
      add_capability "module:CoreDomain:build"
      ;;
    "AREA | CorePersistence")
      add_capability "module:CorePersistence:build"
      ;;
    "AREA | UI System")
      add_capability "module:CoreDesignSystem:test"
      ;;
    "AREA | FeatureHome")
      add_capability "module:FeatureHome:build"
      ;;
    "AREA | FeatureSession")
      add_capability "module:FeatureSession:build"
      ;;
  esac
}

add_capability_for_path() {
  local path="$1"

  case "$path" in
    Docs/*|README.md|Docs.md|AGENTS.md|.github/ISSUE_TEMPLATE/*|.github/PULL_REQUEST_TEMPLATE/*|.github/pull_request_template.md)
      add_capability "docs"
      ;;
    .swiftlint.yml)
      add_capability "swiftlint-config"
      ;;
    .github/workflows/*|scripts/validate_ios_*.sh|scripts/validate_tuist_foundation.sh|scripts/resolve_ios_validation_from_labels.sh)
      add_capability "ci"
      ;;
    .mise.toml|Tuist.swift|Workspace.swift|Tuist/*|Modules/*/Project.swift)
      add_capability "project-setup"
      ;;
    Modules/AppMain/*)
      add_capability "app-main"
      ;;
    Modules/CoreDomain/*)
      add_capability "module:CoreDomain:build"
      ;;
    Modules/CorePersistence/*)
      add_capability "module:CorePersistence:build"
      ;;
    Modules/CoreDesignSystem/*)
      add_capability "module:CoreDesignSystem:test"
      ;;
    Modules/FeatureHome/*)
      add_capability "module:FeatureHome:build"
      ;;
    Modules/FeatureSession/*)
      add_capability "module:FeatureSession:build"
      ;;
    *)
      echo "No iOS validation capability mapping found for changed path: ${path}" >&2
      exit 2
      ;;
  esac
}

record_changed_file() {
  local path="$1"

  [[ -z "$path" ]] && return
  CHANGED_FILES+=("$path")
  add_capability_for_path "$path"
}

collect_changed_files() {
  local changed_files_file="${CLIPY_IOS_CHANGED_FILES_FILE:-}"
  local path

  case "$CHANGED_FILES_FORMAT" in
    lines|nul)
      ;;
    *)
      echo "Unsupported CLIPY_IOS_CHANGED_FILES_FORMAT: ${CHANGED_FILES_FORMAT}" >&2
      exit 2
      ;;
  esac

  # 직접 env로 넘기는 로컬 fixture는 기존 newline 계약을 유지합니다.
  if [[ -n "${CLIPY_IOS_CHANGED_FILES:-}" ]]; then
    while IFS= read -r path; do
      record_changed_file "$path"
    done <<< "$CLIPY_IOS_CHANGED_FILES"
    return
  fi

  if [[ -z "$changed_files_file" ]]; then
    return
  fi
  if [[ ! -f "$changed_files_file" ]]; then
    echo "CLIPY_IOS_CHANGED_FILES_FILE does not exist: ${changed_files_file}" >&2
    exit 2
  fi
  if [[ ! -r "$changed_files_file" ]]; then
    echo "CLIPY_IOS_CHANGED_FILES_FILE is not readable: ${changed_files_file}" >&2
    exit 2
  fi

  if [[ "$CHANGED_FILES_FORMAT" == "nul" ]]; then
    while IFS= read -r -d '' path; do
      record_changed_file "$path"
    done < "$changed_files_file"
  else
    while IFS= read -r path || [[ -n "$path" ]]; do
      record_changed_file "$path"
    done < "$changed_files_file"
  fi
}

has_non_docs_capability() {
  local capability

  for capability in "${CAPABILITIES[@]}"; do
    if [[ "$capability" != "docs" ]]; then
      return 0
    fi
  done

  return 1
}

emit_capabilities() {
  local ordered_capabilities=(
    "docs"
    "ci"
    "project-setup"
    "swiftlint-config"
    "app-main"
    "module:CoreDomain:build"
    "module:CorePersistence:build"
    "module:CoreDesignSystem:build"
    "module:CoreDesignSystem:test"
    "module:FeatureHome:build"
    "module:FeatureSession:build"
  )
  local output=()
  local capability

  for capability in "${ordered_capabilities[@]}"; do
    if contains_capability "$capability" "${CAPABILITIES[@]}"; then
      if [[ "$capability" == "docs" ]] && has_non_docs_capability; then
        continue
      fi
      output+=("$capability")
    fi
  done

  if ((${#output[@]} == 0)); then
    fail "No validation capability mapping found for the provided labels and changed files."
  fi

  printf 'CLIPY_IOS_VALIDATION_PROFILE=capabilities\n'
  printf 'CLIPY_IOS_VALIDATION_CAPABILITIES=%s\n' "${output[*]}"
}

LABELS=()
TYPE_LABELS=()
AREA_LABELS=()
UNSUPPORTED_LABELS=()
UNSUPPORTED_AREA_LABELS=()
CAPABILITIES=()
CHANGED_FILES=()
LABEL_INPUT="$(read_labels)"

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
done <<< "$LABEL_INPUT"

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

for area_label in "${AREA_LABELS[@]}"; do
  add_capability_for_area "$area_label"
done

collect_changed_files

if [[ "$TYPE_LABEL" == "TYPE | Docs" ]] && has_non_docs_capability; then
  echo "TYPE | Docs cannot describe code, project, lint, or CI validation requirements." >&2
  echo "Resolved capabilities: ${CAPABILITIES[*]}" >&2
  exit 2
fi

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Resolved iOS validation labels:" >&2
  printf '  %s\n' "${LABELS[@]}" >&2
  if ((${#CHANGED_FILES[@]} > 0)); then
    echo "Resolved changed files:" >&2
    printf '  %s\n' "${CHANGED_FILES[@]}" >&2
  fi
fi

emit_capabilities
