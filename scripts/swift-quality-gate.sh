#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-local}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

CONFIGURATION="${XCODE_CONFIGURATION:-Debug}"
DESTINATION="${XCODE_DESTINATION:-platform=macOS}"
DERIVED_DATA_PATH="${XCODE_DERIVED_DATA_PATH:-DerivedData}"

find_candidates() {
  local pattern="$1"
  find . \
    \( -path './Pods' -o -path './Carthage' -o -path './DerivedData' -o -path './.build' \) -prune -o \
    -name "$pattern" -print | sort
}

list_schemes() {
  local container_flag="$1"
  local container_path="$2"

  xcodebuild -list -json "$container_flag" "$container_path" 2>/dev/null | \
    ruby -rjson -e '
      input = STDIN.read
      exit if input.strip.empty?
      data = JSON.parse(input)
      container = data["workspace"] || data["project"] || {}
      puts Array(container["schemes"])
    '
}

choose_scheme() {
  local container_flag="$1"
  local container_path="$2"
  local scheme_output
  local scheme_count

  if [ -n "${XCODE_SCHEME:-}" ]; then
    printf '%s\n' "$XCODE_SCHEME"
    return 0
  fi

  scheme_output="$(list_schemes "$container_flag" "$container_path" || true)"
  scheme_count="$(printf '%s\n' "$scheme_output" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"

  if [ "$scheme_count" -eq 1 ]; then
    printf '%s\n' "$scheme_output"
    return 0
  fi

  if [ "$scheme_count" -gt 1 ]; then
    echo "Multiple Xcode schemes found. Set XCODE_SCHEME explicitly." >&2
    printf 'Schemes:\n' >&2
    printf '  %s\n' "$scheme_output" >&2
    return 1
  fi

  echo "No shared Xcode schemes found. Share a scheme or set XCODE_SCHEME explicitly." >&2
  return 1
}

run_swift_package_checks() {
  echo "Using Swift Package Manager quality gate"
  echo "Running Swift build check"
  swift build
  echo "Running Swift test check"
  swift test
}

run_qa_artifact_check() {
  local output_dir
  local generated_file
  local labels=(
    "Healthy"
    "completed-jobs"
    "Watch"
    "Bad"
    "Stale refresh failure"
    "Stale age-out"
    "first-use"
    "empty-watchlist"
    "kubectl failure"
    "pending-human-verification"
  )

  echo "Running QA artifact generation check"
  output_dir="$(mktemp -d)"
  generated_file="${output_dir}/07-UAT.generated.md"

  ./scripts/generate-qa-evidence.sh --output "$output_dir" >/dev/null
  test -s "$generated_file"

  for label in "${labels[@]}"; do
    grep -q "$label" "$generated_file"
  done
}

run_changelog_tool_checks() {
  echo "Running changelog tooling checks"
  ./scripts/test-changelog-tools.sh
}

run_xcode_checks() {
  local workspaces=()
  local projects=()
  local workspace=""
  local project=""
  local container_flag
  local container_path
  local scheme

  while IFS= read -r item; do
    [ -n "$item" ] && workspaces+=("$item")
  done < <(find_candidates '*.xcworkspace')

  while IFS= read -r item; do
    [ -n "$item" ] && projects+=("$item")
  done < <(find_candidates '*.xcodeproj')

  if [ -n "${XCODE_WORKSPACE:-}" ] && [ -n "${XCODE_PROJECT:-}" ]; then
    echo "Set either XCODE_WORKSPACE or XCODE_PROJECT, not both." >&2
    return 1
  fi

  if [ -n "${XCODE_WORKSPACE:-}" ]; then
    workspace="$XCODE_WORKSPACE"
    project=""
  elif [ -n "${XCODE_PROJECT:-}" ]; then
    workspace=""
    project="$XCODE_PROJECT"
  else
    if [ "${#workspaces[@]}" -eq 1 ]; then
      workspace="${workspaces[0]}"
    elif [ "${#workspaces[@]}" -gt 1 ]; then
      echo "Multiple workspaces found. Set XCODE_WORKSPACE explicitly." >&2
      printf 'Candidates:\n' >&2
      printf '  %s\n' "${workspaces[@]}" >&2
      return 1
    else
      workspace=""
    fi

    if [ "${#projects[@]}" -eq 1 ] && [ -z "$workspace" ]; then
      project="${projects[0]}"
    elif [ "${#projects[@]}" -gt 1 ] && [ -z "$workspace" ]; then
      echo "Multiple projects found. Set XCODE_PROJECT explicitly." >&2
      printf 'Candidates:\n' >&2
      printf '  %s\n' "${projects[@]}" >&2
      return 1
    else
      project=""
    fi
  fi

  if [ -n "$workspace" ]; then
    container_flag="-workspace"
    container_path="$workspace"
  elif [ -n "$project" ]; then
    container_flag="-project"
    container_path="$project"
  else
    return 0
  fi

  scheme="$(choose_scheme "$container_flag" "$container_path")"

  echo "Using Xcode container: $container_path"
  echo "Using Xcode scheme: $scheme"
  echo "Using build configuration: $CONFIGURATION"
  echo "Using test destination: $DESTINATION"

  echo "Running Xcode build check"
  xcodebuild "$container_flag" "$container_path" \
    -scheme "$scheme" \
    -configuration "$CONFIGURATION" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build \
    CODE_SIGNING_ALLOWED=NO

  echo "Running Xcode test check"
  xcodebuild "$container_flag" "$container_path" \
    -scheme "$scheme" \
    -configuration "$CONFIGURATION" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    test \
    CODE_SIGNING_ALLOWED=NO
}

main() {
  echo "Swift quality gate mode: $MODE"

  run_changelog_tool_checks

  run_xcode_checks

  if [ -f "Package.swift" ]; then
    run_swift_package_checks
    run_qa_artifact_check
    return 0
  fi

  if ! find . -maxdepth 3 \( -name '*.xcworkspace' -o -name '*.xcodeproj' \) | grep -q .; then
    echo "No Xcode workspace/project or Package.swift found." >&2
    return 1
  fi
}

main
