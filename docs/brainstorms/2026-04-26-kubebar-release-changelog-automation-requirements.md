---
date: 2026-04-26
topic: kubebar-release-changelog-automation
---

# Kubebar Release Changelog Automation

## Problem Frame

Kubebar already has a GitHub tag based release workflow, but release notes
depend on a manually maintained `CHANGELOG.md` section. This is close to
CodexBar's release model, but Kubebar needs stronger checks so a release cannot
silently publish empty, stale, or mismatched notes.

CodexBar's useful pattern is not fully automatic changelog invention. Its
release flow treats the finalized changelog section as the source of truth,
then reuses that same section for GitHub Release notes and, when available,
Sparkle update notes.

## Requirements

**Release Notes Source**
- R1. `CHANGELOG.md` remains the single human-edited source for user-facing
  release notes.
- R2. A release for tag `vX.Y.Z` must publish notes from the matching
  `CHANGELOG.md` section only.
- R3. Release notes must include Kubebar's ad-hoc signing installation warning
  until Kubebar has Developer ID signing and notarization.

**Release Safety**
- R4. The release flow must fail before publishing when the matching changelog
  section is missing, still marked `Unreleased`, or does not match the tag.
- R5. The release flow must fail before publishing when the generated release
  notes are empty.
- R6. The release flow must keep the current package artifact behavior unless
  formal distribution work explicitly changes it.

**Scope Fit**
- R7. The first version should improve GitHub Release notes only.
- R8. Sparkle appcast notes should stay deferred until Kubebar adds a formal
  update channel.
- R9. The release docs should explain that changelog text is curated before
  release, then reused automatically during publishing.

## Success Criteria

- Creating a `vX.Y.Z` tag with a valid matching changelog section produces a
  GitHub Release whose body contains that version's notes plus the ad-hoc
  signing warning.
- Creating a tag without a matching finalized changelog section fails before a
  GitHub Release is created.
- The release checklist no longer implies that release notes need to be copied
  manually into GitHub.
- The release flow remains compatible with the current ad-hoc signed zip
  distribution.

## Scope Boundaries

- No AI-generated changelog text in the first version.
- No automatic changelog generation from commits or pull requests in the first
  version.
- No Sparkle appcast generation until Kubebar has a supported auto-update
  channel.
- No notarization, Homebrew Cask, or Developer ID signing changes in this work.

## Key Decisions

- Use curated changelog reuse rather than generated changelogs: CodexBar's
  current release process depends on finalized human-readable notes, then
  automates reuse and validation.
- Keep the first Kubebar change smaller than CodexBar's full release process:
  CodexBar also signs, notarizes, updates appcast data, and checks assets, but
  Kubebar's current distribution is intentionally ad-hoc.
- Add validation before publishing: the highest-risk failure today is creating
  a release with missing or wrong notes.

## Alternatives Considered

| Option | Pros | Cons | Fit |
| --- | --- | --- | --- |
| Reuse finalized `CHANGELOG.md` section | Predictable, user-facing, matches current repo habits | Still requires someone to curate notes | Recommended |
| Generate notes from commits or PRs | Less manual work | Noisy, misses user impact, requires labeling discipline | Later only |
| Copy CodexBar's full release flow | Strong end-to-end release discipline | Too much for ad-hoc distribution; includes Sparkle and notarization assumptions | Not now |

## Dependencies / Assumptions

- `CHANGELOG.md`, `.github/workflows/release.yml`, `scripts/build-release.sh`,
  and `docs/RELEASING.md` are the relevant Kubebar release surfaces today.
- CodexBar references used for this brainstorm:
  - `https://github.com/steipete/CodexBar/blob/main/docs/RELEASING.md`
  - `https://github.com/steipete/CodexBar/blob/main/Scripts/release.sh`
  - `https://github.com/steipete/CodexBar/blob/main/Scripts/validate_changelog.sh`
  - `https://github.com/steipete/CodexBar/blob/main/Scripts/changelog-to-html.sh`
  - `https://github.com/steipete/CodexBar/blob/main/Scripts/make_appcast.sh`

## Outstanding Questions

### Resolve Before Planning

- None.

### Deferred to Planning

- [Affects R4][Technical] Decide whether validation should live as a dedicated
  script or directly inside the GitHub Actions workflow.
- [Affects R2][Technical] Decide whether Kubebar should keep the current
  Keep a Changelog heading style (`## [X.Y.Z] - YYYY-MM-DD`) or normalize toward
  CodexBar's simpler `## X.Y.Z - YYYY-MM-DD` style.

## Next Steps

-> /ce:plan for structured implementation planning.
