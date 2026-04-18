#!/usr/bin/env bash
set -euo pipefail

CHECK_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --check-only)
      CHECK_ONLY=true
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--check-only]" >&2
      exit 1
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -d "_lang" && ! -f "AGENTS.md" ]]; then
  echo "This repository still looks like the uninitialized template."
  echo "Run ./init.sh first, then re-run ./scripts/dev-setup.sh."
  exit 1
fi

configure_git_hooks() {
  if [[ -d ".git" && -d ".githooks" ]]; then
    git config core.hooksPath .githooks
    echo "Configured git hooks to use .githooks/"
  else
    echo "Skipped git hook configuration (missing .git or .githooks/)"
  fi
}

require_cmd() {
  local cmd="$1"
  local label="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "Found $label: $(command -v "$cmd")"
  else
    echo "Missing required tool: $label ($cmd)"
    return 1
  fi
}

recommend_cmd() {
  local cmd="$1"
  local label="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "Found $label: $(command -v "$cmd")"
  else
    echo "Recommended tool not found yet: $label ($cmd)"
  fi
}

detect_language() {
  if [[ -f "Cargo.toml" ]] || grep -q "Rust Guide" AGENTS.md 2>/dev/null; then
    echo "rust"
  elif [[ -f "package.json" ]] || grep -q "TypeScript Guide" AGENTS.md 2>/dev/null; then
    echo "typescript"
  elif [[ -f "go.mod" ]] || grep -q "Go Guide" AGENTS.md 2>/dev/null; then
    echo "golang"
  elif find . -maxdepth 3 \( -name "*.xcodeproj" -o -name "*.xcworkspace" -o -name "Package.swift" \) | grep -q . || grep -q "Swift Guide" AGENTS.md 2>/dev/null; then
    echo "swift"
  elif [[ -f "pyproject.toml" ]] || grep -q "Python Guide" AGENTS.md 2>/dev/null; then
    echo "python"
  else
    echo "unknown"
  fi
}

setup_rust() {
  local missing=0
  require_cmd cargo "Rust toolchain" || missing=1
  recommend_cmd rustup "rustup"

  if [[ "$CHECK_ONLY" = false && "$missing" -eq 0 ]] && command -v rustup >/dev/null 2>&1; then
    rustup component add rustfmt clippy
  fi

  return "$missing"
}

setup_typescript() {
  local missing=0
  require_cmd node "Node.js" || missing=1
  recommend_cmd corepack "corepack"

  if [[ "$CHECK_ONLY" = false && "$missing" -eq 0 ]] && command -v corepack >/dev/null 2>&1; then
    corepack enable
  fi

  if ! command -v pnpm >/dev/null 2>&1; then
    echo "pnpm is not available yet. Install or activate it before running the quality gate."
  else
    echo "Found pnpm: $(command -v pnpm)"
  fi

  return "$missing"
}

setup_golang() {
  local missing=0
  require_cmd go "Go" || missing=1

  if ! command -v golangci-lint >/dev/null 2>&1; then
    echo "golangci-lint is not installed yet. Install it before running the quality gate."
  else
    echo "Found golangci-lint: $(command -v golangci-lint)"
  fi

  return "$missing"
}

setup_python() {
  local missing=0
  require_cmd python3 "Python 3" || missing=1

  if command -v uv >/dev/null 2>&1; then
    echo "Found uv: $(command -v uv)"
  else
    echo "uv is not installed yet. Install it if this project uses uv-managed dependencies."
  fi

  for tool in ruff mypy pytest; do
    if command -v "$tool" >/dev/null 2>&1; then
      echo "Found $tool: $(command -v "$tool")"
    else
      echo "$tool is not installed yet. Install project dependencies before running the quality gate."
    fi
  done

  return "$missing"
}

setup_swift() {
  local missing=0
  require_cmd swift "Swift toolchain" || missing=1
  require_cmd xcodebuild "Xcode build tools" || missing=1

  if command -v swiftlint >/dev/null 2>&1; then
    echo "Found SwiftLint: $(command -v swiftlint)"
  else
    echo "SwiftLint is optional and not installed yet. Install it only if this project adopts it."
  fi

  return "$missing"
}

main() {
  echo "Running project setup..."
  configure_git_hooks

  local language
  local missing=0
  language="$(detect_language)"
  echo "Detected project language: $language"

  case "$language" in
    rust)
      setup_rust || missing=1
      ;;
    typescript)
      setup_typescript || missing=1
      ;;
    golang)
      setup_golang || missing=1
      ;;
    swift)
      setup_swift || missing=1
      ;;
    python)
      setup_python || missing=1
      ;;
    *)
      echo "Could not detect a supported project language from AGENTS.md or repository files."
      echo "Review AGENTS.md and install the required toolchain manually."
      ;;
  esac

  echo "Setup check finished."
  if [[ "$missing" -eq 1 ]]; then
    echo "Install the missing required tools, then re-run ./scripts/dev-setup.sh."
    exit 1
  fi

  echo "Next: install project dependencies if needed, then run the quality gate from AGENTS.md."
}

main
