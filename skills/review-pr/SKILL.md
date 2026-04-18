---
name: review-pr
version: 1.0.0
description: Use when a pull request needs a serious pre-merge review covering correctness, edge cases, security, tests, documentation, and architecture.
activation:
  patterns:
    - "review.*pr"
    - "code review"
  keywords:
    - review
    - pr
    - pull request
  max_context_tokens: 2500
---

# Review PR

Use this skill when the user wants a serious pre-merge review.

## Preconditions

- `gh auth status` succeeds if GitHub data must be fetched
- The PR belongs to the current repository
- `AGENTS.md` is available for project-specific rules

## Phase 1: Load Context

1. Read `AGENTS.md`.
2. Parse the PR number or URL.
3. Fetch PR metadata and the full diff.
4. Read the PR description and existing comments.

## Phase 2: Read Full Context

Do not review from the diff alone.

For each changed file:
1. read the whole file
2. read nearby callers, imports, tests, and interfaces when needed
3. check both sides of any boundary change

## Phase 3: Review Through 6 Lenses

1. Correctness
2. Edge cases
3. Security
4. Test coverage
5. Documentation
6. Architecture

Always check whether the change follows the rules in `AGENTS.md`.

## Phase 4: Report Findings

Present findings sorted by severity with:
- file and line
- risk
- short explanation
- concrete suggestion

Also give:
- overall assessment
- risk level
- confidence

If the user wants GitHub comments, post the result after presenting it.

## Output Format

Use this structure:

| # | Severity | File:Line | Finding | Suggestion |
|---|---|---|---|---|

Then include:
- Overall assessment: APPROVE | REQUEST_CHANGES | COMMENT
- Risk level: Low | Medium | High | Critical
- Confidence: Low | Medium | High
