---
module: release-tooling
tags:
  - release
  - xcodebuild
  - versioning
  - quality-gate
problem_type: release-metadata-drift
reusability: medium
key_files:
  - scripts/build-release.sh
  - scripts/test-release-build-version.sh
  - scripts/swift-quality-gate.sh
  - project.yml
  - docs/RELEASING.md
next_reuse_scenarios:
  - Changing release artifact naming or publishing flow.
  - Adding CI release automation that sets app bundle metadata.
  - Debugging mismatches between release tags, Xcode build settings, and packaged app Info.plist.
---

# Release Build Version Metadata

## Problem

Kubebar release artifacts need two version values to stay aligned:
the user-facing release version and the app bundle build number. The release
script previously accepted a release version but left the build number fixed in
the generated Xcode build settings, so changing release inputs could produce an
artifact whose `Info.plist` did not reflect the intended build metadata.

## Solution

Treat release app metadata as executable release behavior, not only as project
configuration.

- Keep XcodeGen defaults in `project.yml`, but pass release-specific
  `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` from `scripts/build-release.sh`.
- Resolve the build number in a deterministic order: explicit script argument,
  `BUILD_NUMBER`, then local git commit count.
- Validate the build number before invoking `xcodebuild`.
- Verify the built app's `Info.plist` before signing and zipping the artifact.
- Cover the shell behavior with fake-tool tests in
  `scripts/test-release-build-version.sh`, and run them from the local quality
  gate.

## Evidence

- The release metadata tests first failed against the old fixed
  `CURRENT_PROJECT_VERSION` behavior.
- `scripts/test-release-build-version.sh` now covers explicit build numbers,
  `BUILD_NUMBER`, git-count fallback, invalid build numbers, `Info.plist`
  mismatch detection, and quality-gate wiring.
- `./scripts/test-release-build-version.sh` passed.
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
  passed, including Xcode build/tests and SwiftPM build/tests.
- `git diff --check` passed.

## Reuse Notes

When changing release automation, assert both sides of metadata sync: the inputs
passed to `xcodebuild` and the values written into the packaged app bundle.
Script text checks alone are too weak; fake-tool tests catch command-line drift,
and post-build `Info.plist` checks catch artifact drift before signing or
publishing.

## Reusability Critique

- Falsifiability: this guidance becomes too local if Kubebar stops producing a
  macOS app bundle through Xcode/XcodeGen, or if a future release system owns
  bundle metadata outside `scripts/build-release.sh`.
- Evidence trail: the evidence supports release version metadata behavior only;
  it does not prove broader signing, notarization, Sparkle, or Homebrew release
  guarantees.
- Architecture entropy resistance: no existing solution hub covers release
  tooling, and the lesson is operational rather than architectural. A scoped
  `release-tooling` solution avoids creating an ADR for a reversible script
  policy.
