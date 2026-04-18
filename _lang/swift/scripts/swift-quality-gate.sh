#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-local}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

CONFIGURATION="${XCODE_CONFIGURATION:-Debug}"
DEFAULT_DESTINATION='platform=iOS Simulator,name=iPhone 16'
DESTINATION="${XCODE_DESTINATION:-$DEFAULT_DESTINATION}"

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
    tr -d '\n' | \
    sed -E 's/.*"schemes"[[:space:]]*:[[:space:]]*\[([^]]*)\].*/\1/' | \
    tr ',' '\n' | \
    sed -E 's/^[[:space:]]*"([^"]+)"[[:space:]]*$/\1/' | \
    sed '/^[[:space:]]*$/d'
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

run_xcode_checks() {
  local workspaces=()
  local projects=()
  local workspace
  local project
  local container_flag
  local container_path
  local scheme

  while IFS= read -r item; do
    [ -n "$item" ] && workspaces+=("$item")
  done < <(find_candidates '*.xcworkspace')

  while IFS= read -r item; do
    [ -n "$item" ] && projects+=("$item")
  done < <(find_candidates '*.xcodeproj')

  if [ -n "${XCODE_WORKSPACE:-}" ]; then
    workspace="$XCODE_WORKSPACE"
  elif [ "${#workspaces[@]}" -eq 1 ]; then
    workspace="${workspaces[0]}"
  elif [ "${#workspaces[@]}" -gt 1 ]; then
    echo "Multiple workspaces found. Set XCODE_WORKSPACE explicitly." >&2
    printf 'Candidates:\n' >&2
    printf '  %s\n' "${workspaces[@]}" >&2
    return 1
  else
    workspace=""
  fi

  if [ -n "${XCODE_PROJECT:-}" ]; then
    project="$XCODE_PROJECT"
  elif [ "${#projects[@]}" -eq 1 ]; then
    project="${projects[0]}"
  elif [ "${#projects[@]}" -gt 1 ]; then
    echo "Multiple projects found. Set XCODE_PROJECT explicitly." >&2
    printf 'Candidates:\n' >&2
    printf '  %s\n' "${projects[@]}" >&2
    return 1
  else
    project=""
  fi

  if [ -n "$workspace" ] && [ -n "${XCODE_PROJECT:-}" ]; then
    echo "Set either XCODE_WORKSPACE or XCODE_PROJECT, not both." >&2
    return 1
  fi

  if [ -n "$workspace" ]; then
    container_flag="-workspace"
    container_path="$workspace"
  elif [ -n "$project" ]; then
    container_flag="-project"
    container_path="$project"
  else
    echo "No Xcode workspace or project found. Set XCODE_WORKSPACE or XCODE_PROJECT, or add Package.swift for package-only repositories." >&2
    return 1
  fi

  scheme="$(choose_scheme "$container_flag" "$container_path")"

  echo "Using Xcode container: $container_path"
  echo "Using Xcode scheme: $scheme"
  echo "Using build configuration: $CONFIGURATION"
  echo "Using test destination: $DESTINATION"

  echo "Running Swift build check"
  xcodebuild "$container_flag" "$container_path" \
    -scheme "$scheme" \
    -configuration "$CONFIGURATION" \
    -sdk iphonesimulator \
    build \
    CODE_SIGNING_ALLOWED=NO

  echo "Running Swift test check"
  xcodebuild "$container_flag" "$container_path" \
    -scheme "$scheme" \
    -configuration "$CONFIGURATION" \
    -destination "$DESTINATION" \
    test \
    CODE_SIGNING_ALLOWED=NO
}

main() {
  echo "Swift quality gate mode: $MODE"

  if [ -f "Package.swift" ] && ! find . -maxdepth 3 \( -name '*.xcworkspace' -o -name '*.xcodeproj' \) | grep -q .; then
    run_swift_package_checks
    return 0
  fi

  run_xcode_checks
}

main
