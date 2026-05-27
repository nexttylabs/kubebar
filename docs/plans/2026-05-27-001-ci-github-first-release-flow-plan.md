---
title: "ci: Add GitHub-first release flow"
type: ci
status: planned
date: 2026-05-27
origin: docs/specs/2026-05-27-github-first-release-flow.md
---

# ci: Add GitHub-first release flow

## Summary

- Summary: GitHub Actions can drive changelog review, release preparation, and publishing.

Make GitHub Actions the default release control surface for Kubebar. Release
owners should generate changelog candidates, prepare versioned release notes,
and publish a GitHub Release from GitHub UI workflows, while keeping reviewed
`CHANGELOG.md` text as the source of truth.

## Task

- Type: ci
- Scope: release workflow
- Owner: imm-work
- Verification: automated plus GitHub Actions smoke

## Origin

- Spec: `docs/specs/2026-05-27-github-first-release-flow.md`
- Prior release automation: `docs/brainstorms/2026-04-26-kubebar-release-changelog-automation-requirements.md`
- Existing implementation surfaces:
  `.github/workflows/changelog-candidates.yml`,
  `.github/workflows/release.yml`,
  `scripts/generate-changelog-candidates.sh`,
  `scripts/prepare-changelog-release.sh`,
  `scripts/extract-release-notes.sh`,
  `scripts/build-release.sh`,
  `docs/RELEASING.md`

## Research

- `CHANGELOG.md` already remains the final release history.
- `changelog.d/` is the staging area for reviewed release-note fragments.
- `.github/workflows/changelog-candidates.yml` currently generates artifacts
  from `workflow_dispatch`, but does not create a branch or PR.
- `.github/workflows/release.yml` currently publishes only from pushed `v*`
  tags.
- Existing scripts are shell-first and can be called by Actions without moving
  changelog parsing into workflow YAML.
- Runtime invariants do not apply directly; this is release workflow scope.

## Decisions

- Keep final release notes curated. Automated candidate generation may draft
  fragments, but humans review PRs before `CHANGELOG.md` is finalized.
- Add PR-producing workflows instead of making artifact downloads the normal
  path.
- Keep tag-push publishing as fallback, but add a `workflow_dispatch` publish
  path so release owners do not need local tagging.
- Use existing scripts as the contract for changelog preparation, extraction,
  and packaging.
- Do not introduce formal signing, notarization, Sparkle, or Homebrew behavior.

## Assumptions

- GitHub token permissions can be declared as `contents: write`,
  `pull-requests: write`, and `actions: read` where needed.
- The release owner can approve and merge generated PRs in GitHub.
- If a workflow creates no file changes, it should report that outcome without
  opening an empty PR.

## Devil's Advocate Audit

### Rollback resilience

Candidate and release-preparation workflows should write to release branches
and PRs, so a bad generation can be closed without touching `main`. Publish
workflow changes are rollbackable by reverting workflow commits before the next
release. If a release is published with bad notes, the existing rollback is to
edit the GitHub Release body or revert the release-preparation PR and publish a
corrective release.

### Verification vanity

YAML parsing alone is insufficient because it would not catch missing PR
creation, missing artifact upload, or duplicate release behavior. Verification
must include `gh workflow run` for candidate generation and publish dry-run or
script-level checks that prove release notes can be extracted before publish.

### Spec dilution detection

The plan preserves all requested GitHub-first behavior: candidate generation,
versioned changelog preparation, and automatic publishing. It narrows only the
unsafe part: final release text is not generated straight into
`CHANGELOG.md` without review. That is intentional because existing release
policy treats curated notes as the source of truth.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Changelog candidate generation opens or updates a reviewable GitHub PR.
- Verification: gh workflow run changelog-candidates.yml --repo nexttylabs/kubebar --ref main -f from_ref=v0.3.1 -f to_ref=HEAD -f output_prefix=release-v0.3.2
- Depends on: None
- Test scenarios: workflow with candidates creates a release branch and PR; workflow with no candidates exits successfully without an empty PR; invalid output_prefix fails with a clear message
- Discovery cache: .github/workflows/changelog-candidates.yml (candidate workflow to extend); scripts/generate-changelog-candidates.sh (candidate fragment generator); docs/RELEASING.md (document GitHub-first candidate flow)

**Goal:** Make changelog candidate generation reviewable in GitHub without a
local shell step or manual artifact download.

**Verification type:** hitl

**Requirements:** candidate generation PR, release owner review checkpoint,
GitHub-first release workflow.

**Dependencies:** None

**Files:**
- `.github/workflows/changelog-candidates.yml` (candidate workflow to extend)
- `scripts/generate-changelog-candidates.sh` (candidate fragment generator)
- `docs/RELEASING.md` (document GitHub-first candidate flow)

**Approach:**
- Give the candidate workflow write permissions for contents and pull requests.
- Generate candidates into a deterministic release branch name.
- Use a GitHub Action PR helper or equivalent `gh` commands to open/update a
  candidate review PR.
- Keep no-candidate runs successful and explicit rather than opening empty PRs.
- Update release docs to make this the default candidate path.

**Verification:**
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/changelog-candidates.yml")'`
- `bash -n scripts/generate-changelog-candidates.sh`
- `gh workflow run changelog-candidates.yml --repo nexttylabs/kubebar --ref main -f from_ref=v0.3.1 -f to_ref=HEAD -f output_prefix=release-v0.3.2`
- `gh run view <run-id> --repo nexttylabs/kubebar --json status,conclusion,jobs`

**failure_behavior:** If PR creation fails, keep generated fragments in workflow
logs/artifacts and do not modify `main`.

### Step 2

- Step ID: U2
- Result: Release preparation opens or updates a reviewable CHANGELOG PR.
- Verification: gh workflow run release.yml --repo nexttylabs/kubebar --ref main -f mode=prepare -f version=0.0.0-test -f dry_run=true
- Depends on: 1
- Test scenarios: missing changelog fragments fail during preparation; duplicate version section fails during preparation; dry-run preparation does not push a branch; real preparation opens a PR with one finalized CHANGELOG.md section
- Discovery cache: .github/workflows/release.yml (current tag-push publisher); scripts/prepare-changelog-release.sh (finalizes CHANGELOG.md); scripts/extract-release-notes.sh (release note validation); scripts/build-release.sh (release artifact build); CHANGELOG.md (final release history); docs/RELEASING.md (document GitHub-first release path)

**Goal:** Let release owners convert reviewed fragments into a versioned
`CHANGELOG.md` section from GitHub Actions.

**Verification type:** hitl

**Requirements:** release preparation PR and reviewed `CHANGELOG.md` source of
truth.

**Dependencies:** Step 1

**Files:**
- `.github/workflows/release.yml`
- `scripts/prepare-changelog-release.sh`
- `scripts/extract-release-notes.sh`
- `scripts/build-release.sh`
- `CHANGELOG.md`
- `docs/RELEASING.md`

**Approach:**
- Add a GitHub-triggered release preparation path that runs
  `prepare-changelog-release.sh`, commits `CHANGELOG.md` and fragment removals
  to a release branch, and opens/updates a PR.
- Scope write permissions only to jobs that create branches, tags, PRs, or
  pull requests.

**Verification:**
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/release.yml")'`
- `./scripts/prepare-changelog-release.sh <test-version> <test-date>` in an isolated test fixture or dry-run workflow path
- `./scripts/extract-release-notes.sh <test-version>`
- `gh workflow run release.yml --repo nexttylabs/kubebar --ref main -f mode=prepare -f version=0.0.0-test -f dry_run=true`
- `gh run view <run-id> --repo nexttylabs/kubebar --json status,conclusion,jobs`

**failure_behavior:** If release preparation fails, no release PR is opened.

**security_considerations:** Workflow permissions must be explicit and scoped to
the job that needs them.

### Step 3

- Step ID: U3
- Result: A reviewed release can be published from GitHub Actions.
- Verification: gh workflow run release.yml --repo nexttylabs/kubebar --ref main -f mode=publish -f version=0.0.0-test -f dry_run=true
- Depends on: 2
- Test scenarios: missing finalized notes fail before publishing; dry-run publish does not create a tag or GitHub Release; real publish creates vX.Y.Z, uploads Kubebar.zip, and appends the ad-hoc signing warning; existing tag fails before overwriting release state
- Discovery cache: .github/workflows/release.yml (current tag-push publisher); scripts/extract-release-notes.sh (release note validation); scripts/build-release.sh (release artifact build); CHANGELOG.md (final release history); docs/RELEASING.md (document GitHub-first release path)

**Goal:** Let release owners publish the reviewed version from GitHub Actions
without local tagging.

**Verification type:** hitl

**Requirements:** release publish from GitHub UI and release-note validation
before publish.

**Dependencies:** Step 2

**Files:**
- `.github/workflows/release.yml`
- `scripts/extract-release-notes.sh`
- `scripts/build-release.sh`
- `CHANGELOG.md`
- `docs/RELEASING.md`

**Approach:**
- Add a publish path with `version` and `dry_run` inputs.
- Keep tag-push publishing as fallback.
- Ensure workflow-dispatch publishing validates notes before creating tags or
  GitHub Releases.
- Keep ad-hoc signing installation notes in the release body.
- Fail closed when the tag already exists or when notes extraction fails.

**Verification:**
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/release.yml")'`
- `./scripts/extract-release-notes.sh <test-version>`
- `gh workflow run release.yml --repo nexttylabs/kubebar --ref main -f mode=publish -f version=0.0.0-test -f dry_run=true`
- `gh run view <run-id> --repo nexttylabs/kubebar --json status,conclusion,jobs`

**failure_behavior:** If publish validation fails, no tag or GitHub Release is
created.

**security_considerations:** Release publishing may write tags and GitHub
Releases, so destructive or duplicate-publish paths must fail closed.

## Verification Approach

- Validate workflow YAML locally with Ruby YAML parsing or `actionlint` when
  available.
- Validate changed shell scripts with `bash -n`.
- Use existing changelog scripts for release-note correctness.
- Use `gh workflow run` and `gh run view` for GitHub-side workflow behavior.
- Use publish dry-run before any real release.

## Next Action

Run `imm-plan docs/plans/2026-05-27-001-ci-github-first-release-flow-plan.md --json`
and `imm-plan docs/plans/2026-05-27-001-ci-github-first-release-flow-plan.md --sync`.
If validation passes, continue with `imm-work` on Step GFR-1.
