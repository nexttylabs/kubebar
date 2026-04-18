---
name: triage-prs
version: 1.0.0
description: Use when open pull requests need a read-only dashboard showing review state, scope, blockers, conflicts, and merge readiness.
activation:
  patterns:
    - "triage.*prs"
    - "triage.*pull requests"
  keywords:
    - prs
    - pull requests
    - triage
  max_context_tokens: 2500
---

# Triage PRs

Use this skill for a read-only pull request dashboard.

## Preconditions

- `gh auth status` succeeds
- The repository in GitHub matches the repository you intend to analyze

## Phase 1: Fetch Open PRs

1. Apply any label or author filters.
2. Fetch open PRs with `gh pr list`.
3. Read enough file-level context to understand what each PR touches.

## Phase 2: Classify

For each PR, determine:
- touched modules
- review state
- scope
- change type
- merge blockers

## Phase 3: Detect Risk

Flag:
- merge conflicts
- failing CI
- overlapping files across open PRs
- dependency chains between PRs
- architectural or breaking changes

## Phase 4: Report

Return a dashboard with:
- blocked or failing PRs
- ready-to-merge PRs
- PRs waiting for first review
- PRs with requested changes
- stale reviews
- architectural PRs
- likely conflicts
- recommendations

## Output Format

Use these sections in order:

1. Summary
2. Attention required
3. Ready to merge
4. Needs review
5. Changes requested
6. Stale reviews
7. Architectural PRs
8. Potential conflicts
9. Recommendations
