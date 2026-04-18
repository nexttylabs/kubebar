# Contributing

Thanks for your interest in contributing! This guide covers the process for reporting
issues, submitting changes, and getting your work reviewed.

## Getting Started

```bash
git clone <repo-url>
cd <repo>
./scripts/dev-setup.sh --check-only
```

Install dev dependencies and run any project-specific setup. See `AGENTS.md` for exact
commands — they vary by language and toolchain.

## How to Contribute

- Bug fixes and documentation improvements are always welcome.
- Search existing issues before opening a new one to avoid duplicates.
- Keep each PR focused on a single concern. Mixing unrelated changes slows review and
  makes reverts harder.

## Creating Issues

### Bug Reports

Include all of the following:

- **Expected behavior** — what you expected to happen.
- **Actual behavior** — what happened instead.
- **Reproduction steps** — minimal sequence to trigger the bug.
- **Logs / error output** — stack traces, error messages, or screenshots.
- **Environment** — OS, language/runtime version, dependency versions.

### Feature Requests

- Open an issue before writing code. Describe the problem you are solving, not the
  solution you have in mind.
- Wait for maintainer feedback on scope and approach before investing in a PR.

## Development Workflow

Format, lint, and test your changes locally before pushing. See `AGENTS.md` for the
exact commands to run — they are the source of truth for the quality gate.

## Before You Open a PR

1. Run the full quality gate (see `AGENTS.md`). CI will catch what you miss, but
   local verification is faster and more respectful of reviewer time.
2. Keep the PR focused — one logical change per PR.
3. Fill out the PR template completely.
4. If your change alters user-facing behavior, update the relevant documentation.
5. If the project keeps architecture notes or longer specs in `docs/`, update them in the same branch.

## Review Follow-Through

- Address every reviewer comment. If you disagree, explain why — do not silently
  ignore feedback.
- Resolve conversations only after the fix is pushed, not before.
- Do not leave cleanup, TODOs, or "will fix later" items for maintainers.

## Code Style

See `AGENTS.md` for the full style guidelines and conventions used in this project.

## Behavior Changes

- If your change affects behavior, update the relevant docs, specs, README, API references, or changelog in the same branch.
- If you are working in a high-risk area such as auth, secrets, config, persistence, migrations, CI, or public APIs, call out compatibility and rollback risk in the PR.

## Review Tracks

| Track | Scope | Requirements |
|-------|-------|-------------|
| **A** | Docs, tests, chores | 1 approval + CI green |
| **B** | Features, refactors | 1 approval + CI green + tests covering new behavior |
| **C** | Security, runtime, DB, CI changes | 2 approvals + CI green + rollback plan documented |
