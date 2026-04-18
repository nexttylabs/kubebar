# AI-Native Project Template

A production-ready project template with pre-configured AI-assisted development workflows for **Rust**, **TypeScript**, **Go**, **Python**, and **Swift iOS** projects. Built for **Codex**, with optional **Cursor** rules.

## What You Get

- **AGENTS.md** -- one source of truth for build commands, quality gates, structure, and coding rules
- **GitHub Workflows** -- CI, automated PR labeling, regression-test enforcement
- **Codex Skills** (`skills/`) -- fix-issue, review-pr, pr-shepherd, respond-pr, triage-issues, triage-prs, ship
- **Cursor Rules** (`.cursor/rules/`) -- optional review discipline and testing rules in `.mdc` format
- **Git Hooks** -- regression test enforcement on fix commits, quality gate on push
- **PR Template** -- structured review with security impact, blast radius, rollback plan
- **Shared Skills** -- GitHub API integration, structured planning, pre-merge review checklist

## Quick Start

```bash
# Clone the template
git clone https://github.com/your-org/project-template.git my-project
cd my-project

# Run the interactive setup
./init.sh
```

The setup script will ask for:

1. **Project name** -- used in README, AGENTS.md, and package config
2. **Primary language** -- `rust`, `typescript`, `golang`, `python`, or `swift`
3. **Dev tools** -- `codex`, `both`, or `cursor` (default: codex)

After setup, the `_lang/` directory is removed and all files are customized for your chosen language and tooling.

Then run:

```bash
./scripts/dev-setup.sh --check-only
```

This configures git hooks, checks local toolchain prerequisites, and prepares the project for the language you selected.

## Template Structure

```
.github/
  pull_request_template.md    PR template with review tracks (A/B/C)
  labeler.yml                 Auto-label PRs by file path
  scripts/
    pr-labeler.sh             Classify PRs by size, risk, contributor tier
    create-labels.sh          Bootstrap GitHub labels
  workflows/
    pr-labels.yml             Auto-label on PR open/sync
    ci.yml                    Language-specific CI pipeline
    regression-test-check.yml Enforce tests on fix PRs

skills/
  fix-issue/SKILL.md          Fix a GitHub issue end-to-end
  github/SKILL.md             GitHub API via HTTP tool
  plan-mode/SKILL.md          Structured task planning
  pr-shepherd/SKILL.md        Full PR lifecycle management
  respond-pr/SKILL.md         Triage and fix review comments
  review-checklist/SKILL.md   Pre-merge review checklist
  review-pr/SKILL.md          Deep PR review
  ship/SKILL.md               Quality gate before shipping
  triage-issues/SKILL.md      Issue triage dashboard
  triage-prs/SKILL.md         PR triage dashboard

docs/architecture/
  README.md                   Place deeper subsystem and invariant docs here

scripts/
  dev-setup.sh                Configure hooks and verify local toolchain setup
  check_no_panics.py          Rust-only changed-line guard for panic-style code

.cursor/rules/                Cursor context-aware rules
  review-discipline.mdc       Same content, Cursor format
  testing.mdc                 Same content, Cursor format

.githooks/
  commit-msg                  Require regression tests on fix commits
  pre-push                    Run quality gate before push

AGENTS.md                     Development guide for Codex and human contributors
CONTRIBUTING.md               Human contributor guide
```

## Language Support

| | Rust | TypeScript | Go | Python | Swift iOS |
|---|---|---|---|---|---|
| **Build** | `cargo build` | `pnpm build` | `go build ./...` | `python -m build` | `xcodebuild build` or `swift build` |
| **Test** | `cargo test` | `pnpm test` | `go test ./...` | `pytest` | `xcodebuild test` or `swift test` |
| **Lint** | `cargo clippy` | `eslint` / `biome` | `golangci-lint run` | `ruff check` | `SwiftLint` (optional) |
| **Format** | `cargo fmt` | `prettier --check` | `gofmt -l .` | `ruff format --check` | `swift-format` or Xcode formatter (optional) |
| **CI** | rust-toolchain | setup-node + pnpm | setup-go | setup-python | macOS + `xcodebuild` |

Swift projects use `./scripts/swift-quality-gate.sh` as the shared entry point for local checks and CI. The template auto-detects a single `.xcodeproj` or `.xcworkspace` plus a single shared scheme. For repositories with multiple choices, set `XCODE_WORKSPACE`, `XCODE_PROJECT`, `XCODE_SCHEME`, and `XCODE_DESTINATION` explicitly.

## PR Review Tracks

| Track | Scope | Requirements |
|---|---|---|
| **A** | Docs, tests, chore, dependency bumps | 1 approval + CI green |
| **B** | Features, refactors, new tools | 1 approval + CI green + test evidence |
| **C** | Security, runtime, database, CI | 2 approvals + rollback plan documented |

## Customization

After running `init.sh`, all files are fully yours to customize:

- **AGENTS.md** -- add project-specific architecture, commands, and conventions
- **docs/architecture/** -- move deeper subsystem notes and invariants out of the quick-start guide
- **labeler.yml** -- add scope labels matching your directory structure
- **skills/** -- add or revise Codex workflows for your team
- **.cursor/rules/** -- extend Cursor support if you use it

## License

This template is provided under MIT license. Replace with your project's license after setup.
