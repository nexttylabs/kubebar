---
name: pr-shepherd
version: 1.0.0
description: Use when a pull request needs one coordinated workflow covering review state, fixes, checks, branch updates, and merge readiness.
activation:
  patterns:
    - "shepherd.*pr"
    - "manage.*pr"
  keywords:
    - pr
    - review
    - merge
  max_context_tokens: 3000
---

# PR Shepherd

Use this skill when the user wants one workflow to handle a pull request from review through merge readiness.

## Preconditions

- `gh auth status` succeeds
- The PR belongs to the current repository
- `AGENTS.md` defines the quality gate for the project

## Phase 1: Situational Awareness

1. Read `AGENTS.md`.
2. Fetch PR metadata with `gh pr view`.
3. Determine:
   - review state
   - CI status
   - mergeability
   - unresolved comments
4. Check out the PR branch with `gh pr checkout`.

## Phase 2: Triage

If the PR already has review comments:
- fetch comments and reviews
- group them by concern
- classify them as code change, reply only, or user decision

If there are no comments or the user asked for a fresh review:
- read the changed files in full
- review for correctness, edge cases, security, tests, documentation, and architecture

## Phase 3: Fix

For each approved code change:
1. implement the fix
2. update tests if behavior changed
3. self-review the result

## Phase 4: Quality Gate

Run the checks defined in `AGENTS.md` in order. If a step fails, fix it and re-run.

## Phase 5: Push and Follow Through

1. Stage and commit the approved fixes.
2. Push when the user wants the branch updated.
3. Reply to resolved GitHub threads with a short explanation of what changed.
4. Watch CI and, if it fails, diagnose, fix, and repeat within a bounded retry loop.

## Phase 6: Merge Decision

Only recommend merge when:
- CI is green
- no blocking review comments remain
- the PR is mergeable
- the user explicitly wants to merge

## Output Format

Return these sections in order:

1. Current PR state
2. Triage summary
3. Applied fixes
4. Verification and CI status
5. Merge recommendation
