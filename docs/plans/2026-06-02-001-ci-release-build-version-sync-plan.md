---
title: "ci: Sync release build version metadata"
type: ci
status: planned
date: 2026-06-02
origin: docs/specs/2026-06-02-release-build-version-sync.md
---

# ci: Sync release build version metadata

## Summary

- Summary: Release artifacts should carry both the selected marketing version
  and a non-static build number.

Kubebar's release path should stop publishing app bundles whose
`CFBundleVersion` is always `1`. The release build script should resolve a build
number, pass it to Xcode, and verify the generated app bundle before packaging.

## Task

- Type: ci
- Scope: release build metadata
- Owner: imm-work
- Verification: automated

## Origin

- Spec: `docs/specs/2026-06-02-release-build-version-sync.md`
- Brainstorm: chat framing from 2026-06-02
- Existing implementation surfaces:
  `scripts/build-release.sh`,
  `scripts/swift-quality-gate.sh`,
  `project.yml`,
  `.github/workflows/release.yml`,
  `docs/RELEASING.md`

## Brainstorm manifest

- BR-REQ-1: Release builds must set both marketing version and build version.
- BR-REQ-2: Build version must not remain fixed at `1`.
- BR-DEC-1: Default build number comes from git commit count and can be
  overridden by CI/env.
- BR-OUT-1: Do not add in-app version display in this slice.
- BR-OUT-2: Do not introduce Sparkle/Appcast in this slice.

## Brainstorm Trace

| ID | Status | Mapping |
| --- | --- | --- |
| BR-REQ-1 | covered_by_step | U1 sets and verifies both release metadata fields. |
| BR-REQ-2 | covered_by_step | U1 removes the static `CURRENT_PROJECT_VERSION=1` release behavior. |
| BR-DEC-1 | captured_as_decision | Build number resolution defaults to git count with explicit override. |
| BR-OUT-1 | out_of_scope | No runtime app UI is needed to fix release metadata. |
| BR-OUT-2 | out_of_scope | Update distribution is a future release-system feature. |

## Research

- `scripts/build-release.sh` currently calls Xcode with
  `MARKETING_VERSION="$1"` and `CURRENT_PROJECT_VERSION="1"`.
- Release publishing in `.github/workflows/release.yml` calls
  `./scripts/build-release.sh ${{ steps.release.outputs.version }}` after
  resolving the changelog version.
- `project.yml` is the durable XcodeGen source; direct edits to
  `Kubebar.xcodeproj/project.pbxproj` are generated-output churn.
- The existing quality gate runs changelog tooling checks before Xcode and
  SwiftPM checks, so release metadata script tests can be wired into the same
  local gate.
- The rejected resource-history alerting decision does not apply; this is
  release metadata, not runtime monitoring.

## Decisions

- Keep `MARKETING_VERSION` equal to the release version selected by the release
  workflow or local release owner.
- Resolve `CURRENT_PROJECT_VERSION` from, in order, explicit script argument,
  `BUILD_NUMBER`, then `git rev-list --count HEAD`.
- Use a simple integer build number.
- Validate requested and generated metadata with shell tests plus an app bundle
  `Info.plist` check in the release script.
- Keep the existing GitHub workflow invocation compatible; no release owner
  workflow input is required for the normal path.
- Do not add signing, notarization, Sparkle, Homebrew, or runtime version UI.

## Assumptions

- Release owners run release builds from a git checkout.
- `xcodegen`, `xcodebuild`, `codesign`, and `plutil`/`PlistBuddy` remain
  available in the current release environment.
- A re-run for the same commit and release version may reuse the same build
  number; that is acceptable because the tag/release path already avoids
  overwriting an existing release.

## Devil's Advocate Audit

### Rollback resilience

The change is limited to release tooling and docs. If the script change fails
mid-release, the workflow fails before creating or uploading `Kubebar.zip`.
Rollback is reverting the release-tooling commit; no Kubernetes runtime state,
user config, or published artifact is mutated by a failed build.

### Verification vanity

Checking only that the script contains a variable would be vanity. Verification
must execute script-level tests that prove override precedence, default build
number behavior, invalid build-number rejection, and metadata verification
failure. The release script itself must check the built bundle's `Info.plist`,
so a wrong Xcode setting fails before packaging.

### Spec dilution detection

The plan covers all confirmed brainstorm items: both version fields are set,
`CURRENT_PROJECT_VERSION=1` is removed from release behavior, git-count default
and override are preserved, and runtime version display plus Sparkle are kept
out of scope.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Release builds carry synchronized app version metadata.
- Verification: ./scripts/test-release-build-version.sh && ./scripts/swift-quality-gate.sh local
- Depends on: None
- Test scenarios: explicit argument overrides build number; BUILD_NUMBER overrides git count; git count is the local default; invalid build numbers fail; mismatched built Info.plist metadata fails; quality gate runs release metadata tests
- Discovery cache: scripts/build-release.sh (release metadata source); project.yml (XcodeGen version settings source); scripts/swift-quality-gate.sh (local gate integration); docs/RELEASING.md (release owner behavior)

**Goal:** Make `Kubebar.zip` release artifacts carry the selected
`MARKETING_VERSION` and a non-static `CURRENT_PROJECT_VERSION`.

**Execution note:** test-first

**Files:**
- `scripts/build-release.sh`
- `scripts/test-release-build-version.sh`
- `scripts/swift-quality-gate.sh`
- `project.yml`
- `docs/RELEASING.md`

**Approach:**
- Add a small script-level feedback loop for release build metadata resolution
  and metadata validation behavior.
- Update `build-release.sh` to validate the release version argument, resolve
  the build number from explicit argument, `BUILD_NUMBER`, or git commit count,
  and pass it to Xcode as `CURRENT_PROJECT_VERSION`.
- After copying the built app bundle, read `Info.plist` and fail if
  `CFBundleShortVersionString` or `CFBundleVersion` differs from the requested
  metadata.
- Keep `project.yml` aligned with generated version settings so XcodeGen remains
  the source of truth.
- Wire the new release metadata test into the local quality gate and document
  the default/override behavior.

**Verification:**
- `./scripts/test-release-build-version.sh`
- `./scripts/swift-quality-gate.sh local`

**failure_behavior:** If metadata resolution or app bundle verification fails,
the release build exits before signing, zipping, tagging, or publishing.

**security_considerations:** Version metadata must not read secrets or alter
signing behavior.
