---
name: triage-issues
version: 1.0.0
description: Use when a GitHub issue backlog needs read-only classification, prioritization, duplicate spotting, or clarification gaps called out.
activation:
  patterns:
    - "triage.*issues"
    - "review.*issues"
  keywords:
    - issues
    - triage
    - backlog
  max_context_tokens: 2500
---

# Triage Issues

Use this skill for read-only issue analysis.

## Preconditions

- `gh auth status` succeeds
- The repository in GitHub matches the repository you intend to analyze

## Phase 1: Fetch Open Issues

1. Apply any label or milestone filters from the user.
2. Fetch open issues with `gh issue list`.
3. Read bodies and comments for the issues in scope.

## Phase 2: Classify

For each issue, label it as:
- bug
- feature
- chore
- ambiguous

Also rate whether it is:
- well-specified
- adequate
- under-specified

## Phase 3: Rank

- Rank bugs by impact, urgency, and scope
- Rank features by value, effort, and readiness
- Flag likely duplicates
- Flag stale issues

## Phase 4: Report

Return:
- summary counts
- top bugs
- top features
- under-specified issues
- duplicates
- stale items
- 3 to 5 recommendations

## Output Format

Use these sections in order:

1. Summary
2. Top priority bugs
3. Top opportunity features
4. Under-specified issues
5. Likely duplicates
6. Stale issues
7. Recommendations
