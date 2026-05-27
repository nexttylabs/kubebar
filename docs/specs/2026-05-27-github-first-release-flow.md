---
date: 2026-05-27
topic: github-first-release-flow
---

# GitHub-first Release Flow

## Problem Frame

Kubebar release work still requires local commands for changelog candidate
creation, changelog finalization, tagging, and publishing. The repository now
has scripts for each part, but release owners should be able to drive the
normal path from GitHub Actions while keeping release notes reviewable before
they become final `CHANGELOG.md` text.

## Intended Behavior

- A release owner can trigger changelog candidate generation from GitHub.
- Generated `changelog.d/` fragments are committed to a release branch and
  opened as a pull request for review.
- A release owner can trigger release preparation from GitHub after candidate
  review, producing a `CHANGELOG.md` release PR.
- A release owner can publish from GitHub after the release PR lands, producing
  the tag, `Kubebar.zip`, and GitHub Release without local shell steps.
- `CHANGELOG.md` remains the final source of release notes.

## Scope

- Update GitHub Actions workflow behavior for changelog candidates, release
  preparation, and publishing.
- Reuse existing scripts where possible:
  `scripts/generate-changelog-candidates.sh`,
  `scripts/prepare-changelog-release.sh`,
  `scripts/extract-release-notes.sh`, and `scripts/build-release.sh`.
- Update release documentation so the GitHub-first path is the documented
  default.

## Non-goals

- No AI-authored final release notes.
- No Sparkle appcast.
- No notarization, Developer ID signing, or Homebrew Cask.
- No change to `Kubebar.zip` packaging semantics.
- No change to Kubebar runtime health behavior.

## Success Criteria

- Running the changelog candidate workflow opens or updates a PR containing
  generated candidate fragments.
- Running the release preparation workflow opens or updates a PR containing a
  finalized `CHANGELOG.md` section for the selected version.
- Running the publish workflow on merged release notes creates a tag and GitHub
  Release with `Kubebar.zip`.
- Missing or empty release notes fail before publishing.
- The documented local path remains available as fallback, but is no longer the
  normal release-owner path.

## Assumptions

- GitHub Actions `GITHUB_TOKEN` has permission to create branches, pull
  requests, tags, and releases when the workflow declares the required
  permissions.
- Release owners will review candidate and release-preparation PRs before
  publishing.
- The current ad-hoc signing warning remains required in GitHub Release notes.
