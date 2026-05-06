---
title: docs: Polish README release path
type: docs
status: completed
date: 2026-05-06
origin: docs/brainstorms/2026-05-06-kubebar-readme-release-polish-requirements.md
---

# docs: Polish README release path

## Summary

Update README as the primary surface, backed by a small `docs/assets/readme/`
image set and existing permission/release documentation. The work reuses local
documentation patterns, keeps release wording accurate against GitHub's latest
release, and avoids app/runtime changes.

---

## Problem Frame

The origin document defines this as a launch-facing README improvement, not an
app behavior change: readers should understand what Kubebar is, see real app
states, find the correct release/source links, and trust the local security
boundary before installing.

---

## Requirements

- R1. The README hero description clearly states: "Kubebar is a native macOS
  menu bar for Kubernetes health."
- R2. The top of README includes explicit `[Download latest release]` and
  `[Star this repo]` text links.
- R3. CTA, release, clone, and footer links use `nexttylabs/kubebar` surfaces.
- R4. README shows a core hero screenshot or GIF for the primary menu bar
  experience.
- R5. `docs/assets/readme/` contains named state screenshots for Setup,
  Healthy, Unhealthy/Watch, and Stale.
- R6. README surfaces the state screenshots compactly without becoming a full
  product tour.
- R7. README adds "Why You Can Trust It" with local-only, existing `kubectl`,
  no credential storage, and no telemetry claims grounded in
  `docs/PERMISSIONS.md`.
- R8. README install instructions remove "Coming Soon" placeholders and point
  to a concrete `Kubebar.zip` release path.
- R9. README source build instructions use the correct clone URL.
- R10. README release copy does not misrepresent an older release as the latest
  release when GitHub shows a newer published release.

**Origin actors:** A1 Kubernetes operator, A2 New contributor, A3 Maintainer
**Origin flows:** F1 README first impression, F2 Install confidence check
**Origin acceptance examples:** AE1 first-screen CTA/value proposition, AE2
visual state proof, AE3 trust/install accuracy, AE4 latest-vs-pinned release
wording

---

## Scope Boundaries

- No app behavior, health evaluation, setup flow, or runtime security changes.
- No notarization, Sparkle, Homebrew, formal signing, or release automation.
- No broad README rewrite or documentation site.
- No QA screenshot tooling refactor.
- No claim that `v0.2.0` is latest while newer GitHub releases exist.

### Deferred to Follow-Up Work

- Formal distribution polish: notarization, Sparkle updates, and Homebrew
  remain future distribution work.
- Broader documentation refresh: architecture, roadmap, and release-process
  rewrites stay outside this README-first plan.

---

## Context & Research

### Relevant Code and Patterns

- `README.md` already contains product framing and install sections, but still
  has a placeholder precompiled-download heading and stale `nextty/kubebar`
  links.
- `docs/PERMISSIONS.md` contains the trust claims to reuse: local-only design,
  `kubectl` dependency, no Kubernetes credential storage, no remote telemetry,
  no Secret reads, and process isolation.
- `docs/qa/operator-verification.md` documents deterministic QA states and
  screenshot evidence rules that can guide any needed image capture.
- Existing screenshots live under `docs/screenshots/` and can seed the README
  asset set when they match the required states.
- Existing docs plans keep README work concise and avoid overclaiming product
  completeness.

### Institutional Learnings

- No directly relevant `docs/solutions/` learning exists for README/asset
  polish. The only current solution note covers health-evaluation logic and is
  outside this documentation-only scope.

### External References

- GitHub release data for `nexttylabs/kubebar` shows `v0.2.2` as the current
  latest published release and confirms `v0.2.0` exists with `Kubebar.zip`.

---

## Key Technical Decisions

- Use the GitHub latest-release URL for the top `[Download latest release]`
  CTA: this satisfies the requested label without hard-coding stale latest
  semantics. Mention `v0.2.0` only where the copy explicitly says it is a
  concrete release, not the latest.
- Create a dedicated README asset set under `docs/assets/readme/`: README
  images should be stable and named for README intent, even if initially copied
  from `docs/screenshots/` or QA captures.
- Prefer screenshot reuse before recapture: copy suitable existing screenshots
  into the README asset directory first; capture missing Setup/Stale states
  only when no existing image can satisfy the requirement.
- Keep verification lightweight but explicit: documentation checks should prove
  links, image paths, required text, and release wording; the repo quality gate
  remains final implementation verification because AGENTS.md requires it before
  finishing changes.

---

## Open Questions

### Resolved During Planning

- Latest release link target: use GitHub's latest-release URL for the top CTA,
  and avoid describing `v0.2.0` as latest because newer published releases
  exist.
- Screenshot source: reuse/copy existing screenshots where they match the
  required state, then capture only missing states through the existing QA-state
  workflow.

### Deferred to Implementation

- Exact final screenshots: implementation should inspect the existing images
  and decide whether they adequately represent Setup, Healthy, Unhealthy/Watch,
  and Stale before recapturing.
- Hero image format: use a static screenshot unless a maintained GIF already
  exists or is cheap to capture without adding tooling.

---

## Output Structure

    docs/assets/readme/
      hero-menu.png
      setup.png
      healthy.png
      unhealthy-watch.png
      stale.png

The names above are the expected README-facing asset names. If implementation
uses a GIF for the hero, keep the same semantic name with the appropriate file
extension.

---

## Implementation Units

### U1. Prepare README Asset Set

**Goal:** Create the README-specific visual proof assets with stable names.

**Requirements:** R4, R5, R6, AE2

**Dependencies:** None

**Files:**
- Create: `docs/assets/readme/hero-menu.png`
- Create: `docs/assets/readme/setup.png`
- Create: `docs/assets/readme/healthy.png`
- Create: `docs/assets/readme/unhealthy-watch.png`
- Create: `docs/assets/readme/stale.png`
- Reference: `docs/screenshots/overview-warning.png`
- Reference: `docs/screenshots/overview-normal.png`
- Reference: `docs/screenshots/pods.png`
- Reference: `docs/screenshots/nodes.png`
- Reference: `docs/qa/operator-verification.md`

**Approach:**
- Inspect existing screenshots for whether they already represent the required
  states.
- Copy or move suitable screenshots into `docs/assets/readme/` with
  README-facing names.
- For missing states, use the existing QA-state guidance to capture the minimum
  additional screenshots needed.
- Keep screenshots free of raw command output, kubeconfig paths, full JSON,
  tokens, or sensitive cluster details.

**Patterns to follow:**
- `docs/qa/operator-verification.md` evidence rules.
- Existing image dimensions and menu framing from `docs/screenshots/`.

**Test scenarios:**
- Test expectation: none -- binary screenshot assets have no executable unit
  tests. Verification is path existence, README rendering, and visual review.

**Verification:**
- `docs/assets/readme/` contains all required README asset names.
- Each asset renders as an image and maps clearly to its intended state.
- No README asset exposes sensitive cluster details or raw command output.

---

### U2. Rewrite README First Screen and Visual Proof

**Goal:** Make the first README screen state the value proposition, expose the
two primary actions, and show the product visually.

**Requirements:** R1, R2, R3, R4, R6, AE1, AE2

**Dependencies:** U1

**Files:**
- Modify: `README.md`
- Reference: `docs/assets/readme/hero-menu.png`
- Reference: `docs/assets/readme/setup.png`
- Reference: `docs/assets/readme/healthy.png`
- Reference: `docs/assets/readme/unhealthy-watch.png`
- Reference: `docs/assets/readme/stale.png`

**Approach:**
- Add the two requested top links immediately under the title or opening
  identity block.
- Replace the current opening description with the exact required hero value
  proposition, then keep supporting copy short and watchlist-first.
- Replace the existing single screenshot/TODO block with the README hero asset
  and compact state images.
- Keep the visual section focused on proof of real states, not feature
  explanation or a marketing-style tour.

**Patterns to follow:**
- Existing concise README tone.
- The older docs cleanup plan's guidance to keep README factual and avoid
  overclaiming completeness.

**Test scenarios:**
- Test expectation: none -- Markdown/documentation-only update with no
  executable behavior.

**Verification:**
- README first screen contains the exact hero value proposition.
- README contains `[Download latest release]` and `[Star this repo]` text
  links.
- README image references resolve to `docs/assets/readme/` assets.
- README no longer contains the hero screenshot TODO placeholder.

---

### U3. Add Trust and Install Clarity

**Goal:** Make installation and security boundaries accurate before a reader
downloads the app.

**Requirements:** R3, R7, R8, R9, R10, AE3, AE4

**Dependencies:** None

**Files:**
- Modify: `README.md`
- Reference: `docs/PERMISSIONS.md`
- Reference: `docs/RELEASING.md`

**Approach:**
- Add a "Why You Can Trust It" section that summarizes only the security claims
  already supported by `docs/PERMISSIONS.md`.
- Remove "Coming Soon" from precompiled download instructions.
- Link the top download CTA to GitHub's latest-release surface.
- In install copy, point readers to the current release list and mention the
  concrete `Kubebar.zip` asset path without calling `v0.2.0` latest.
- Fix clone and repository links from `nextty/kubebar` to
  `nexttylabs/kubebar`.
- Preserve existing Gatekeeper/ad-hoc signing guidance, keeping signing
  limitations visible rather than hiding them.

**Patterns to follow:**
- `docs/PERMISSIONS.md` for trust claims.
- `docs/RELEASING.md` for ad-hoc signing and release-install caveats.

**Test scenarios:**
- Test expectation: none -- Markdown/documentation-only update with no
  executable behavior.

**Verification:**
- README has no `Coming Soon` placeholder.
- README has no `nextty/kubebar` URL.
- Trust bullets are traceable to `docs/PERMISSIONS.md` and do not add new
  unsupported security claims.
- Latest-release copy and `v0.2.0` copy are semantically distinct.

---

### U4. Verify README Integrity

**Goal:** Catch broken Markdown, stale links, missing assets, and accidental
scope expansion before finishing.

**Requirements:** R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, AE1, AE2, AE3, AE4

**Dependencies:** U1, U2, U3

**Files:**
- Verify: `README.md`
- Verify: `docs/assets/readme/hero-menu.png`
- Verify: `docs/assets/readme/setup.png`
- Verify: `docs/assets/readme/healthy.png`
- Verify: `docs/assets/readme/unhealthy-watch.png`
- Verify: `docs/assets/readme/stale.png`

**Approach:**
- Check README text for the exact value proposition, CTA labels, expected trust
  section, and absence of stale placeholders/URLs.
- Check every README image path points at an existing file.
- Check release wording against GitHub release state so `latest` does not point
  to a pinned older tag.
- Review the final diff to confirm the change is documentation/assets only.
- Run the repo's standard local quality gate before marking implementation
  complete.

**Patterns to follow:**
- AGENTS.md build and test guidance.
- Prior docs plans' discipline of verifying docs-only changes did not touch
  runtime files.

**Test scenarios:**
- Test expectation: none -- this is verification of documentation and image
  references, not app behavior.

**Verification:**
- Required README text and links are present.
- Required assets exist and render.
- Search confirms stale `nextty/kubebar` and "Coming Soon" strings are gone
  from README.
- Final diff is limited to README, README assets, and planning artifacts unless
  implementation explicitly reports why a supporting docs change was required.
- Repo quality gate passes or any environment failure is reported with the
  exact blocker.

---

## System-Wide Impact

- **Interaction graph:** README becomes the main entry point to release,
  trust, and visual-state documentation; app runtime entry points are unchanged.
- **Error propagation:** No runtime errors are introduced. Documentation errors
  surface as broken links, missing images, or inaccurate release copy.
- **State lifecycle risks:** No app state is changed. README screenshots must
  not imply stale data is healthy or current.
- **API surface parity:** No public API, CLI, or configuration surface changes.
- **Integration coverage:** GitHub README rendering and release-link semantics
  need human-readable verification; unit tests alone do not cover them.
- **Unchanged invariants:** `HealthEvaluator` remains the source of severity,
  UI still renders display models, Kubebar still uses app-owned context and
  local `kubectl` access, and stale data must never look healthy.

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| README says `latest` while linking to an older pinned release | Use GitHub's latest-release URL for the CTA and keep any `v0.2.0` mention explicitly pinned |
| Existing screenshots do not cover Setup or Stale states | Capture only the missing states using the existing QA-state guidance |
| Trust section overclaims security | Limit claims to `docs/PERMISSIONS.md` and retain Gatekeeper/ad-hoc signing caveats |
| README becomes too large | Keep state screenshots compact and avoid a full product tour |
| Binary assets bloat the repo unnecessarily | Reuse existing images where possible and avoid adding duplicate near-identical captures |

---

## Documentation / Operational Notes

- This plan updates user-facing documentation only; no rollout or migration is
  required.
- Because README changes affect installation decisions, final review should
  treat release links and security claims as user-visible behavior.
- If screenshots are captured during implementation, update or reference
  `docs/qa/operator-verification.md` only if the evidence process changes;
  otherwise leave QA docs untouched.

---

## Sources & References

- **Origin document:** [docs/brainstorms/2026-05-06-kubebar-readme-release-polish-requirements.md](../brainstorms/2026-05-06-kubebar-readme-release-polish-requirements.md)
- README: [README.md](../../README.md)
- Permissions: [docs/PERMISSIONS.md](../PERMISSIONS.md)
- Release docs: [docs/RELEASING.md](../RELEASING.md)
- QA evidence guidance: [docs/qa/operator-verification.md](../qa/operator-verification.md)
- Existing screenshots: [docs/screenshots/overview-warning.png](../screenshots/overview-warning.png),
  [docs/screenshots/overview-normal.png](../screenshots/overview-normal.png),
  [docs/screenshots/pods.png](../screenshots/pods.png),
  [docs/screenshots/nodes.png](../screenshots/nodes.png)
- GitHub releases: https://github.com/nexttylabs/kubebar/releases
