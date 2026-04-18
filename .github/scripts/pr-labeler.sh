#!/usr/bin/env bash
# Classify a PR by size, risk, and contributor tier.
# Called by the pr-labels workflow.
#
# Inputs (env vars):
#   PR_NUMBER  -- pull request number
#   REPO       -- owner/repo
#
# Requires: gh CLI, jq
set -euo pipefail

PR_NUMBER="${PR_NUMBER:?PR_NUMBER is required}"
REPO="${REPO:?REPO is required}"

# Remove all labels in a dimension except the desired one.
set_exclusive_label() {
  local prefix="$1" desired="$2"
  local current
  current=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json labels --jq '.labels[].name')

  while IFS= read -r label; do
    [[ -z "$label" ]] && continue
    if [[ "$label" == "${prefix}:"* && "$label" != "$desired" ]]; then
      gh pr edit "$PR_NUMBER" --repo "$REPO" --remove-label "$label" 2>/dev/null || true
    fi
  done <<< "$current"

  gh pr edit "$PR_NUMBER" --repo "$REPO" --add-label "$desired"
}

# --- Size classification ---
classify_size() {
  local total
  total=$(gh api "repos/${REPO}/pulls/${PR_NUMBER}/files" \
    --paginate --jq '
      [.[] | select(.filename | test("\\.(md|txt|rst|adoc)$") | not) | .changes]
      | add // 0
    ')

  local label
  if   (( total < 10 ));  then label="size: XS"
  elif (( total < 50 ));  then label="size: S"
  elif (( total < 200 )); then label="size: M"
  elif (( total < 500 )); then label="size: L"
  else                         label="size: XL"
  fi

  echo "Size: ${total} changed lines -> ${label}"
  set_exclusive_label "size" "$label"
}

# --- Risk classification ---
classify_risk() {
  local current
  current=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json labels --jq '.labels[].name')
  if echo "$current" | grep -qx "risk: manual"; then
    echo "Risk: skipped (manual override)"
    return
  fi

  local files
  files=$(gh api "repos/${REPO}/pulls/${PR_NUMBER}/files" \
    --paginate --jq '.[].filename')

  local risk="low"

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$f" in
      .github/workflows/*|*.yml)
        risk="medium";;
      *secret*|*auth*|*credential*|*permission*)
        risk="high"; break;;
      *migration*|*schema*)
        risk="high"; break;;
    esac
  done <<< "$files"

  echo "Risk: ${risk}"
  set_exclusive_label "risk" "risk: ${risk}"
}

# --- Contributor tier ---
classify_tier() {
  local author
  author=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json author --jq '.author.login')

  local permission
  permission=$(gh api "repos/${REPO}/collaborators/${author}/permission" --jq '.permission' 2>/dev/null || echo "none")

  local label
  case "$permission" in
    admin|maintain|write) label="tier: maintainer";;
    *)
      local pr_count
      pr_count=$(gh pr list --repo "$REPO" --author "$author" --state merged --limit 1 --json number --jq 'length')
      if (( pr_count == 0 )); then
        label="tier: first-time"
      else
        label="tier: contributor"
      fi
      ;;
  esac

  echo "Tier: ${author} -> ${label}"
  set_exclusive_label "tier" "$label"
}

classify_size
classify_risk
classify_tier
