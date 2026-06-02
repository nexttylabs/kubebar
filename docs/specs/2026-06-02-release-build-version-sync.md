---
date: 2026-06-02
topic: release-build-version-sync
---

# Release Build Version Sync

## Problem Frame

Kubebar's release build currently passes the selected release version into
`MARKETING_VERSION`, but leaves `CURRENT_PROJECT_VERSION` fixed at `1`. That
means different published versions can carry the same app bundle build number,
which is poor release metadata and blocks a clean future update story.

## Intended Behavior

- Release builds set `MARKETING_VERSION` from the selected release version.
- Release builds set `CURRENT_PROJECT_VERSION` to a non-static build number.
- The build number defaults to a deterministic repo-derived value for local
  release builds.
- CI or release owners can override the build number explicitly when needed.
- The packaged app is checked after build so release metadata mistakes fail
  before `Kubebar.zip` is published.

## Scope

- Update release build scripting around `scripts/build-release.sh`.
- Keep the XcodeGen source of truth in `project.yml` aligned with generated
  version settings.
- Add automated shell-level verification for release build metadata behavior.
- Update release documentation so release owners know how the build number is
  resolved and overridden.

## Non-goals

- No Sparkle appcast.
- No notarization or Developer ID signing.
- No Homebrew Cask.
- No app UI for displaying versions.
- No change to changelog preparation or GitHub Release note extraction.

## Success Criteria

- A release build for version `X.Y.Z` passes `MARKETING_VERSION=X.Y.Z` and a
  non-static `CURRENT_PROJECT_VERSION` to Xcode.
- The default build number is not hard-coded to `1`.
- A release owner can override the build number with an environment variable or
  optional script argument.
- The release script fails if the built app's `Info.plist` does not match the
  requested marketing version and build number.
- The Swift quality gate runs the new release metadata script tests.

## Assumptions

- A simple integer build number is acceptable for `CFBundleVersion`.
- `git rev-list --count HEAD` is available in normal local and GitHub Actions
  release runs.
- GitHub Actions can continue calling `scripts/build-release.sh <version>`;
  explicit build-number override is optional.
