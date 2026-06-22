---
date: 2026-06-22
topic: release-flow-simplification
---

# Release Flow Simplification

## Problem Frame

Kubebar's GitHub-first release flow works, but the documented main path is too
easy to misread: a successful publish dry-run validates and uploads an Actions
artifact, yet it intentionally does not create a tag or GitHub Release. This
made `v0.5.0` look published-ready while the remote repository still had no
`v0.5.0` tag or release.

## Intended Behavior

- Release owners see a short default path: prepare reviewed release notes, then
  publish once.
- Optional validation steps remain available, but they are clearly labeled as
  optional and non-publishing.
- Publish dry-runs make the non-publishing outcome explicit in workflow logs.
- The existing safety checks remain: finalized changelog section, quality gate,
  packaging, tag availability, and GitHub Release creation only on non-dry-run
  publish.

## Scope

- Update release documentation so the default checklist is prepare then publish.
- Keep changelog candidate generation and publish dry-run as optional tools.
- Add explicit GitHub Actions log messages for dry-run publish behavior.
- Preserve the existing `Release` workflow modes and release artifact behavior.

## Non-goals

- No real `v0.5.0` publish as part of this change.
- No notarization, Developer ID signing, Sparkle appcast, or Homebrew Cask.
- No change to app runtime health behavior.
- No removal of the dry-run capability.

## Success Criteria

- A release owner can read `docs/RELEASING.md` and identify the shortest normal
  path without mistaking dry-run success for publication.
- A publish dry-run workflow emits an explicit message that no tag or GitHub
  Release was created.
- Existing release workflow syntax and changelog tooling checks still pass.

## Assumptions

- Release owners still want a manual final publish trigger instead of automatic
  publication after merging the release notes PR.
- The current workflow inputs remain acceptable; the simplification is mainly
  documentation and guardrail messaging.
