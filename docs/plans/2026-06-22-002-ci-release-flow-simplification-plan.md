---
title: "ci: Simplify release flow"
type: ci
status: planned
date: 2026-06-22
origin: docs/specs/2026-06-22-release-flow-simplification.md
---

# ci: Simplify release flow

## Summary

- Summary: Release owners can follow a clearer prepare-then-publish path.

Clarify Kubebar's release process so dry-run validation is visibly optional and
cannot be mistaken for publication. Keep the current GitHub Actions release
safety checks, but make workflow logs and documentation say when no tag or
GitHub Release is created.

## Task

- Type: ci
- Scope: release workflow documentation and guardrail messaging
- Owner: imm-work
- Verification: automated

## Output Language

Spec and Plan prose are English. Schema fields, commands, file paths, workflow
input names, and canonical terms stay literal.

## Origin

- User request: "先改流程"
- Brainstorm finding: `v0.5.0` release notes were prepared, but the latest
  publish run was a dry-run, so no tag or GitHub Release was created.
- Spec: `docs/specs/2026-06-22-release-flow-simplification.md`
- Prior release flow spec: `docs/specs/2026-05-27-github-first-release-flow.md`

## Research

- `docs/RELEASING.md` currently lists six checklist items, including candidate
  generation and publish dry-run in the main path.
- `.github/workflows/release.yml` already creates tags and GitHub Releases only
  when `mode=publish` and `dry_run=false`.
- A successful dry-run publish can still upload a `Kubebar-vX.Y.Z` Actions
  artifact, which is useful validation but not a public release.
- `CHANGELOG.md` already contains a finalized `0.5.0` section; this plan does
  not publish it.

## Decisions

- Reduce the normal release checklist to three release-owner outcomes:
  finalize changes, prepare notes, publish.
- Move changelog candidate generation and publish dry-run into optional
  validation sections.
- Add a dedicated dry-run summary step to the publish job so successful dry-runs
  state that no tag or GitHub Release was created.
- Keep existing workflow inputs and safety conditions to avoid changing release
  authority or removing the fallback tag-push path.

## Assumptions

- Documentation and workflow messaging are enough for this slice; deeper
  workflow input redesign can be deferred unless the next release still causes
  confusion.
- The release owner can run a real publish after this change by selecting
  `mode=publish`, `version=<target>`, and `dry_run=false`.

## Devil's Advocate Audit

### Rollback resilience

The change is limited to documentation and one non-publishing workflow log
message. If the wording is wrong, it can be reverted without touching release
artifacts, tags, or app runtime code.

### Verification vanity

Checking only that text exists would be weak. Verification must parse workflow
YAML, run release shell tooling checks, and inspect the workflow condition so
the dry-run message cannot fire during real publish.

### Spec dilution detection

The accepted scope is simplifying the release flow, not publishing `v0.5.0`.
This plan covers the real confusion point: dry-run success looked like publish
success. It intentionally does not remove optional safety tools because that
would weaken release validation.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Publish dry-runs cannot be mistaken for public release success.
- Verification: ruby -e 'require "yaml"; YAML.load_file(".github/workflows/release.yml")' && ./scripts/test-changelog-tools.sh && ./scripts/test-release-build-version.sh
- Depends on: None
- Test scenarios: default checklist no longer requires candidate generation or publish dry-run; publish dry-run logs an explicit no-tag/no-release summary; real publish path remains conditioned on dry_run != true
- Discovery cache: docs/RELEASING.md (release-owner checklist); .github/workflows/release.yml (publish dry-run and real publish conditions); scripts/test-changelog-tools.sh (release-note tooling regression check); scripts/test-release-build-version.sh (release packaging metadata check)

**Goal:** Make the release-owner path shorter and prevent dry-run success from
being mistaken for public release success.

**Requirements:** simplify release checklist, preserve optional dry-run,
preserve existing publish safeguards.

**Dependencies:** None

**Files:**
- `docs/RELEASING.md`
- `.github/workflows/release.yml`

**Approach:**
- Rewrite the top checklist around the normal prepare-then-publish path.
- Move candidate generation and dry-run publish into clearly optional sections.
- Add a publish dry-run summary step guarded by `dry_run == true`.
- Keep tag creation and GitHub Release creation conditions unchanged.

**Verification:**
- `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/release.yml")'`
- `./scripts/test-changelog-tools.sh`
- `./scripts/test-release-build-version.sh`

**failure_behavior:** If release tooling checks fail, stop before publishing
guidance is treated as ready.

**security_considerations:** The workflow still uses `contents: write` for
publish because it can create tags and releases; this change must not widen
permissions.

## Verification Approach

- Validate workflow YAML syntax.
- Run release/changelog script checks locally.
- Review the workflow conditions around dry-run, tag creation, and GitHub
  Release creation.
