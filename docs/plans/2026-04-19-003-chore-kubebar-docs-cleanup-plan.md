---
title: chore: Clean up Kubebar product docs
type: chore
status: active
date: 2026-04-19
origin: docs/brainstorms/2026-04-19-kubebar-docs-cleanup-requirements.md
---

# chore: Clean up Kubebar product docs

## Overview

Clean up the repository documentation so a new reader sees Kubebar as the
current product, not as a leftover Swift iOS template effort. The work updates
the main README, makes the architecture entry point reflect existing Kubebar
notes, removes stale template-era docs from the active docs tree, and verifies
that the cleanup did not affect app behavior.

## Problem Frame

Issue #2 asks for the docs to match the current app state and product roadmap.
The origin requirements define the goal as documentation clarity only: preserve
Kubebar's current behavior while removing stale framing and making the roadmap
easy to find (see origin:
`docs/brainstorms/2026-04-19-kubebar-docs-cleanup-requirements.md`).

## Requirements Trace

- R1. README describes Kubebar as a macOS menu bar app for Kubernetes status.
- R2. README does not describe existing setup or menu wiring as only planned.
- R3. README points to the current roadmap entry point.
- R4. `docs/superpowers/` no longer appears active.
- R5. Template-era Swift iOS support notes are removed from active docs.
- R6. Historical material treatment favors a clear first impression.
- R7. `docs/architecture/README.md` reflects existing architecture notes.
- R8. Architecture docs stay focused on Kubebar runtime boundaries.
- R9. Product docs explain Kubebar without prior chat history.
- R10. Local quality checks still pass.
- R11. No product behavior, build setting, or runtime default changes.

## Scope Boundaries

- No app functionality changes.
- No roadmap rewrite beyond making the current roadmap discoverable.
- No changes to watchlist, setup, refresh, or packaging product decisions.
- No broad documentation site.

## Context & Research

### Relevant Code and Patterns

- `README.md` already has the correct product identity, build instructions, and
  layout, but its current-status section still says setup screens and live menu
  wiring are planned.
- `Kubebar/Views/SetupView.swift`, `Kubebar/Views/MenuBarRootView.swift`, and
  `Kubebar/MenuBarViewModel.swift` confirm setup and live menu wiring exist.
- `docs/architecture/system-overview.md` and
  `docs/architecture/runtime-invariants.md` are active Kubebar architecture
  notes.
- `docs/architecture/README.md` still reads like a placeholder.
- `docs/superpowers/` contains Swift iOS template-era plan/spec files that do
  not describe Kubebar.
- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md` is the current roadmap
  entry point.

### Institutional Learnings

- No relevant `docs/solutions/` learnings were found during the brainstorm for
  this documentation cleanup.

### External References

- None. The work is based on the repository's own issue, requirements, and
  current docs.

## Key Decisions

- **Remove stale template docs from active docs:** Keeps the repository's first
  impression focused on Kubebar; Git history is enough preservation for the old
  template notes.
- **Update README status without overclaiming:** Name what exists now and leave
  unfinished product work to the roadmap.
- **Make architecture README an index:** It should guide readers to the active
  architecture notes instead of describing future placeholders.
- **Verify without changing behavior:** The implementation should be docs-only,
  followed by the local quality gate required by the repo.

## Open Questions

### Resolved During Planning

- **Delete or archive `docs/superpowers/`?** Delete from the active docs tree.
  The origin requirements prefer removal, and visible archival would still
  create distraction for new contributors.

### Deferred to Implementation

- **Exact README wording:** Choose concise wording while editing, as long as it
  satisfies R1-R3 and does not duplicate the roadmap.

## Implementation Units

- [x] **Unit 1: Refresh README product status**

**Goal:** Make README accurately describe the current Kubebar app state and
point to the active roadmap.

**Requirements:** R1, R2, R3, R9

**Dependencies:** None

**Files:**
- Modify: `README.md`

**Approach:**
- Keep the existing product framing because it already matches Kubebar.
- Replace stale "planned next" wording with a current-status description that
  acknowledges the existing app shell, setup flow, menu content, config, refresh
  coordination, and tests.
- Add
  `docs/plans/2026-04-19-002-kubebar-product-roadmap.md`
  to the Product Direction section so new readers find the current roadmap
  first.

**Patterns to follow:**
- Existing concise README style.
- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md` for current product
  sequencing.

**Test scenarios:**
- Test expectation: none -- documentation-only update with no executable
  behavior.

**Verification:**
- README no longer says setup screens or live menu wiring are only planned.
- README clearly points readers to the current roadmap.
- README remains concise and product-focused.

- [x] **Unit 2: Update architecture docs index**

**Goal:** Make the architecture entry point identify the current Kubebar
architecture notes.

**Requirements:** R7, R8, R9

**Dependencies:** Unit 1 is not required, but both should stay consistent.

**Files:**
- Modify: `docs/architecture/README.md`

**Approach:**
- Replace placeholder language with a short index for the active architecture
  docs.
- Point readers to `docs/architecture/system-overview.md` and
  `docs/architecture/runtime-invariants.md`.
- Keep suggested future architecture docs clearly marked as future additions,
  not current sources of truth.

**Patterns to follow:**
- `docs/architecture/system-overview.md`
- `docs/architecture/runtime-invariants.md`
- `AGENTS.md` guidance that longer subsystem explanations belong under
  `docs/architecture/`.

**Test scenarios:**
- Test expectation: none -- documentation-only update with no executable
  behavior.

**Verification:**
- Architecture README no longer reads like no architecture notes exist.
- It directs readers to the active Kubebar architecture docs.

- [x] **Unit 3: Remove stale template docs and verify**

**Goal:** Remove old Swift iOS template notes from active product docs and
confirm the repository remains healthy.

**Requirements:** R4, R5, R6, R10, R11

**Dependencies:** Units 1-2 should already make the active docs self-contained.

**Files:**
- Delete: `docs/superpowers/specs/2026-04-08-swift-ios-support-design.md`
- Delete: `docs/superpowers/plans/2026-04-08-swift-ios-support.md`

**Approach:**
- Delete the template-era files rather than moving them elsewhere in `docs/`.
- Confirm no active README, roadmap, or architecture page depends on those
  files.
- Run the local Swift quality gate after the docs cleanup.

**Patterns to follow:**
- Issue #2 acceptance criteria.
- `AGENTS.md` build and test guidance.

**Test scenarios:**
- Test expectation: none -- documentation removal only. Repository verification
  is covered by the quality gate.

**Verification:**
- `docs/superpowers/` is gone or empty after stale files are removed.
- Searching docs no longer surfaces active Swift iOS template guidance.
- `./scripts/swift-quality-gate.sh local` passes.
- Git diff shows docs-only changes, plus the requirements and plan artifacts.

## Risks & Dependencies

| Risk | Mitigation |
| --- | --- |
| README overstates app completeness | Keep status factual and let the roadmap carry future work |
| Removing template notes hides useful history | Rely on Git history; the files are unrelated to Kubebar's active docs |
| Docs cleanup accidentally changes product files | Restrict edits to README and docs; verify diff before finishing |
| Quality gate fails for an unrelated environment reason | Report the exact failure and keep the docs change scoped |

## Documentation / Operational Notes

- This plan is itself a documentation artifact for GitHub #2.
- No runtime rollout is required.
- No user-facing app behavior changes are expected.

## Sources & References

- **Origin document:** [2026-04-19-kubebar-docs-cleanup-requirements.md](../brainstorms/2026-04-19-kubebar-docs-cleanup-requirements.md)
- **GitHub issue:** https://github.com/nexttylabs/kubebar/issues/2
- **Roadmap:** [2026-04-19-002-kubebar-product-roadmap.md](2026-04-19-002-kubebar-product-roadmap.md)
- **Architecture notes:** [system-overview.md](../architecture/system-overview.md),
  [runtime-invariants.md](../architecture/runtime-invariants.md)
