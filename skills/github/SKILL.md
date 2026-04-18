---
name: github
version: 1.0.0
description: Use when working with GitHub repositories, issues, pull requests, branches, or commits and the task needs authenticated repository operations or GitHub metadata.
activation:
  keywords:
    - github
    - issues
    - pull request
    - repository
    - commit
    - branch
  exclude:
    - gitlab
    - bitbucket
  patterns:
    - "list.*issues"
    - "show.*issue"
    - "get.*issue"
    - "create.*issue"
    - "list.*pull"
    - "create.*pull"
    - "get.*repo"
    - "list.*branches"
    - "list.*commits"
  tags:
    - git
    - code-review
    - devops
  max_context_tokens: 2000
---

# GitHub Integration

Prefer the GitHub plugin when it is available. Otherwise prefer the `gh` CLI for authenticated operations in this repository. Only use the REST API directly when the environment explicitly supports injected GitHub credentials.

## Preflight

Before doing any write action:

1. Confirm the target repository.
2. Confirm `gh auth status` succeeds if you plan to use the CLI.
3. Confirm issue titles, PR titles, labels, and comment bodies with the user before creating or posting.

## Common `gh` Commands

### Issues

```bash
gh issue list --state open --limit 100
gh issue view <number> --json number,title,body,labels,comments,assignees,milestone
gh issue create
gh issue comment <number> --body "<text>"
```

### Pull Requests

```bash
gh pr list --state open --limit 100
gh pr view <number> --json number,title,body,author,files,labels,reviews,comments,statusCheckRollup
gh pr diff <number>
gh pr checkout <number>
gh pr create
gh pr comment <number> --body "<text>"
gh pr review <number> --comment --body "<text>"
```

### Repository

```bash
gh repo view --json name,owner,defaultBranchRef
gh api repos/{owner}/{repo}/branches
gh api repos/{owner}/{repo}/commits
```

## REST API Fallback

Use direct API calls only when the environment supports them.

- Base URL: `https://api.github.com`
- Header: `Accept: application/vnd.github+json`
- Never add an `Authorization` header unless the environment explicitly requires manual auth.
- Prefer `per_page=100` for paginated endpoints.

## Rules

1. Prefer GitHub plugin or `gh` over raw HTTP when both are available.
2. Confirm all write actions with the user before creating, editing, commenting, reviewing, or merging.
3. Summarize large diffs instead of dumping raw output unless the user asks for it.
4. If authentication or repo context is missing, stop and surface the exact blocker.
