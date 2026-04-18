---
name: fix-issue
version: 1.0.0
description: Use when a GitHub issue should be handled end-to-end, including issue analysis, code changes, tests, verification, and an optional commit.
activation:
  patterns:
    - "fix.*issue"
    - "implement.*issue"
  keywords:
    - issue
    - github
    - bug
    - fix
  max_context_tokens: 3000
---

# Fix Issue

Use this skill when the user wants an issue handled from start to finish.

## Preconditions

- `gh auth status` succeeds
- The current repository matches the issue's repository
- `AGENTS.md` exists or the project has another clear source of build and verification rules

## Phase 1: Resolve the Issue

1. Parse the user input to extract the issue number or URL.
2. Fetch the issue details:
   ```bash
   gh issue view <number> --json number,title,body,labels,comments,assignees,milestone
   ```
3. Summarize:
   - What is broken or requested
   - Where it likely lives
   - Acceptance criteria
   - Constraints or related issues

## Phase 2: Create a Branch

1. Ensure the working tree is clean with `git status --porcelain`.
2. Update the default branch.
3. Create a fix branch:
   ```bash
   git checkout -b fix/<number>-<slug>
   ```

## Phase 3: Load Project Context

1. Read `AGENTS.md` first.
2. Re-read the issue with the project rules in mind.
3. Identify likely files, tests, and risks.

## Phase 4: Research

1. Search for issue keywords, module names, and error strings.
2. Read all relevant files, not just the first match.
3. Trace the affected path from entry to failure or desired behavior.
4. Find tests that already touch the same area.

## Phase 5: Plan

Present a short structured plan and wait for approval before editing code.

Include:
- Files to change
- Tests to add or update
- Risks or trade-offs
- Scope estimate

Follow `skills/plan-mode/SKILL.md` when writing the plan.

## Phase 6: Implement

1. Make the approved changes.
2. Add or update tests.
3. Re-read every changed file for correctness, naming, and error handling.

## Phase 7: Quality Gate

Run the quality gate defined in `AGENTS.md`. Stop on the first failure, fix it, and re-run.

If `AGENTS.md` does not define the needed checks, ask the user how to verify the change.

## Phase 8: Commit

1. Stage changes with `git add -A`.
2. Commit with an issue-referencing message.
3. Do not push unless the user asks.

## Output Format

Return these sections in order:

1. Issue summary
2. Proposed plan
3. Verification result
4. Final outcome
