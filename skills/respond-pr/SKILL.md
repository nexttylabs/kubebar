---
name: respond-pr
version: 1.0.0
description: Use when a pull request already has review feedback that needs triage, code changes, verification, and clear replies back to reviewers.
activation:
  patterns:
    - "respond.*review"
    - "address.*review"
  keywords:
    - review
    - feedback
    - pr
  max_context_tokens: 2500
---

# Respond to PR Review Comments

## Preconditions

- `gh auth status` succeeds
- The PR belongs to the current repository
- `AGENTS.md` defines the quality gate for the project

## Phase 1: Find the PR

1. Use the provided PR number or URL.
2. If none is provided, try `gh pr view --json number,title,headRefName`.
3. Read `AGENTS.md`.

## Phase 2: Fetch Review Feedback

Collect:
- inline PR comments
- review summaries
- general PR conversation comments

Record author, location, body, thread grouping, and whether the comment is resolved.

## Phase 3: Deduplicate and Triage

Group overlapping comments into one action item per concern.

Present a table with:
- reviewer
- file and line
- category
- severity
- planned action

Wait for confirmation before changing code.

## Phase 4: Implement

For each approved fix:
1. read the full file for context
2. implement the change
3. update tests when behavior changes
4. self-review

## Phase 5: Verify and Reply

1. Run the quality gate from `AGENTS.md`.
2. Commit and push when appropriate.
3. Reply to each thread with either:
   - what was fixed
   - why no code change was needed
   - what decision still needs input

## Output Format

Present:

- A triage table before edits
- A verification summary after edits
- A reply summary listing each thread and its response type
