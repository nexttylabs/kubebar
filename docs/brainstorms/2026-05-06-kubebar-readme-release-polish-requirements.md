---
date: 2026-05-06
topic: kubebar-readme-release-polish
---

# Kubebar README Release Polish Requirements

## Summary

Update the README so a new visitor immediately understands Kubebar's native
macOS menu bar value, sees a direct release/download path, can inspect visual
proof of core states, and has a clear security trust boundary before installing.

---

## Problem Frame

Kubebar has moved beyond early product scaffolding, but the README still has
launch-facing gaps: the first description is close but not exact, top-level
actions are missing, the install section still carries placeholder language,
and the existing visual evidence does not present the full setup and health
state story. A reader deciding whether to try a Kubernetes menu bar app needs
to understand what it is, see what it looks like, and know whether it will touch
credentials, send data, or bypass their existing `kubectl` setup.

The current README also links to `nextty/kubebar`, while the repository remote
is `nexttylabs/kubebar`. Release links and clone instructions need to be
consistent with the real public repository.

---

## Actors

- A1. Kubernetes operator: Evaluates whether Kubebar is worth installing for
  glanceable cluster health.
- A2. New contributor: Uses README links and docs to understand the product and
  find the current release path.
- A3. Maintainer: Needs the README to advertise releases accurately without
  overclaiming signing, telemetry, or security behavior.

---

## Key Flows

- F1. README first impression
  - **Trigger:** A reader opens the repository homepage.
  - **Actors:** A1, A2
  - **Steps:** The reader sees top CTA links, reads the one-line value
    proposition, scans the hero visual, and decides whether to keep reading.
  - **Outcome:** The reader knows Kubebar is a native macOS menu bar for
    Kubernetes health and can immediately find download and star actions.
  - **Covered by:** R1, R2, R3

- F2. Install confidence check
  - **Trigger:** A reader reaches the install and trust sections.
  - **Actors:** A1, A3
  - **Steps:** The reader follows the release download path, checks source
    build instructions if needed, and reviews the security claims.
  - **Outcome:** The reader has an accurate install path and understands that
    Kubebar relies on local `kubectl` access rather than owning credentials.
  - **Covered by:** R4, R5, R6, R7

---

## Requirements

**Positioning and CTAs**
- R1. The README hero description must clearly state:
  "Kubebar is a native macOS menu bar for Kubernetes health."
- R2. The top of the README must include explicit text links labeled
  `[Download latest release]` and `[Star this repo]`.
- R3. The CTA links must point to the real `nexttylabs/kubebar` repository
  surfaces, not the stale `nextty/kubebar` URL.

**Visual proof**
- R4. The README must show a core hero screenshot or GIF that demonstrates the
  app's primary menu bar experience.
- R5. `docs/assets/readme/` must contain four named state screenshots for
  Setup, Healthy, Unhealthy/Watch, and Stale.
- R6. The README must surface those state screenshots in a compact way that
  helps readers understand the product states without turning the README into a
  full product tour.

**Trust and install clarity**
- R7. The README must add a "Why You Can Trust It" section that highlights the
  security boundary: local-only operation, use of existing `kubectl`, no storage
  of Kubernetes credentials, and no telemetry.
- R8. The install section must remove "Coming Soon" placeholders and point to a
  concrete GitHub Release path for downloading `Kubebar.zip`.
- R9. The install section must fix clone URLs to use `nexttylabs/kubebar`.
- R10. The release link copy must not misrepresent an older release as the
  current latest release if GitHub shows a newer published release.

---

## Acceptance Examples

- AE1. **Covers R1, R2, R3.** Given a reader opens the README, when they scan
  the first screen, they see the exact product value proposition and two
  explicit top links for downloading the latest release and starring the repo.
- AE2. **Covers R4, R5, R6.** Given the README renders on GitHub, when a reader
  scans the visual section, they can see the main app experience plus Setup,
  Healthy, Unhealthy/Watch, and Stale states from assets stored under
  `docs/assets/readme/`.
- AE3. **Covers R7, R8, R9.** Given a reader is evaluating installation risk,
  when they read the trust and install sections, they see accurate local-only
  security claims and working `nexttylabs/kubebar` release/source links.
- AE4. **Covers R10.** Given GitHub publishes releases newer than `v0.2.0`,
  when README uses "latest release" copy, the link target must resolve to the
  actual latest release or the copy must explicitly say it is pinned to
  `v0.2.0`.

---

## Success Criteria

- A new reader understands Kubebar's product category and value in the first
  screen of the README.
- The README provides direct, accurate actions for downloading and starring the
  repository.
- The visual section proves the app has real setup and health states rather
  than placeholder UI.
- The trust section makes the local security boundary visible before install.
- A downstream planner can implement the README update without inventing CTA
  labels, required visual states, security claims, or release-link behavior.

---

## Scope Boundaries

- This work does not change app behavior, health evaluation, setup flow, or
  runtime security behavior.
- This work does not add notarization, Sparkle updates, Homebrew distribution,
  or formal signing.
- This work does not create a documentation site or a broad README rewrite
  beyond the first-impression, visual proof, trust, and install sections.
- This work does not require generating new app states if suitable existing
  screenshots already exist; planning may choose whether to capture, move, or
  reuse assets.

---

## Key Decisions

- Use a new focused requirements document rather than expanding the older docs
  cleanup brainstorm: the older doc covered stale template cleanup, while this
  work is about README conversion, release trust, and install clarity.
- Keep the trust claims narrow and verifiable: "local-only", "uses existing
  `kubectl`", "does not store Kubernetes credentials", and "no telemetry" are
  the claims the README should highlight.
- Treat `v0.2.0` as a concrete release path to verify, not automatically as
  "latest": repository release data shows newer published releases exist, so
  the final README must avoid inaccurate "latest" wording.

---

## Dependencies / Assumptions

- The public repository is `https://github.com/nexttylabs/kubebar`.
- `v0.2.0` exists as a published GitHub Release and includes `Kubebar.zip`.
- GitHub currently shows newer published releases after `v0.2.0`, so "latest"
  release link behavior needs a deliberate choice during implementation.
- `docs/PERMISSIONS.md` is the authoritative source for README security claims.

---

## Outstanding Questions

### Deferred to Planning

- [Affects R4, R5][Technical] Decide whether to reuse existing screenshots from
  `docs/screenshots/`, move/copy them into `docs/assets/readme/`, or capture new
  screenshots/GIFs for the exact README states.
- [Affects R2, R8, R10][Maintainer decision] Decide whether the top "Download
  latest release" link should use GitHub's latest-release URL or whether README
  should intentionally pin download instructions to `v0.2.0` with non-latest
  wording.
