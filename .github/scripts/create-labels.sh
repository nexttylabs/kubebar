#!/usr/bin/env bash
# Create standard labels for the repository.
# Usage: REPO=owner/repo ./create-labels.sh
set -euo pipefail

REPO="${REPO:?REPO is required (e.g. owner/repo)}"

create_label() {
  local name="$1" color="$2" description="$3"
  gh label create "$name" --repo "$REPO" --color "$color" --description "$description" --force
}

# Size labels
create_label "size: XS"  "0e8a16" "< 10 lines changed"
create_label "size: S"   "1d76db" "10-49 lines changed"
create_label "size: M"   "fbca04" "50-199 lines changed"
create_label "size: L"   "d93f0b" "200-499 lines changed"
create_label "size: XL"  "b60205" "500+ lines changed"

# Risk labels
create_label "risk: low"     "0e8a16" "Low risk change"
create_label "risk: medium"  "fbca04" "Medium risk change"
create_label "risk: high"    "d93f0b" "High risk change"
create_label "risk: manual"  "5319e7" "Risk manually overridden"

# Tier labels
create_label "tier: maintainer"  "0075ca" "From a maintainer"
create_label "tier: contributor" "bfd4f2" "From a contributor"
create_label "tier: first-time"  "e4e669" "First-time contributor"

# Type labels
create_label "bug"           "d73a4a" "Something is broken"
create_label "enhancement"   "a2eeef" "New feature or improvement"
create_label "documentation" "0075ca" "Documentation change"
create_label "refactor"      "d4c5f9" "Code refactor"
create_label "security"      "b60205" "Security-related change"
create_label "dependencies"  "0366d6" "Dependency update"
create_label "ci"            "fbca04" "CI/CD change"

# Process labels
create_label "skip-regression-check"  "e4e669" "Skip regression test requirement"

echo "Labels created for $REPO"
