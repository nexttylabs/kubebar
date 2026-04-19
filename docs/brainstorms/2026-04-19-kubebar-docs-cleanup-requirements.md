---
date: 2026-04-19
topic: kubebar-docs-cleanup
origin: https://github.com/nexttylabs/kubebar/issues/2
---

# Kubebar Docs Cleanup Requirements

## Problem Frame

Kubebar is now a native macOS menu bar app for quickly checking Kubernetes
health, but parts of the documentation still reflect an older template-era
Swift iOS support effort. A new reader should be able to open the repository
and immediately understand the current product, the current roadmap, and which
documents are active.

The cleanup should remove stale framing without changing product behavior.

## Requirements

**Current product identity**
- R1. README must describe Kubebar as a macOS menu bar app for Kubernetes
  status, not as a generic project template or Swift support scaffold.
- R2. README must not describe setup screens or live menu wiring as only
  planned if the repository already contains those pieces.
- R3. README must point readers to the current roadmap entry point:
  `docs/plans/2026-04-19-002-kubebar-product-roadmap.md`.

**Historical template material**
- R4. `docs/superpowers/` must no longer appear to be active Kubebar product
  documentation.
- R5. Template-era Swift iOS support notes must be removed from the active docs
  tree.
- R6. The chosen treatment for historical material must favor a clear first
  impression for new contributors over preserving duplicate context in the
  active docs tree.

**Architecture and roadmap clarity**
- R7. `docs/architecture/README.md` must reflect that architecture notes
  already exist, rather than reading like a placeholder for future notes.
- R8. Architecture docs must stay focused on Kubebar runtime boundaries,
  freshness rules, watchlist behavior, and external command boundaries.
- R9. Product docs must explain Kubebar without relying on prior chat history.

**Verification**
- R10. Local quality checks must still pass after the documentation cleanup.
- R11. The cleanup must not change product behavior, build settings, or runtime
  defaults.

## Success Criteria

- A new reader understands Kubebar's purpose from README without encountering
  stale template language.
- Current roadmap and architecture docs are easy to find from the main docs.
- Old Swift iOS template material is removed from the active Kubebar product
  documentation.
- The repository still passes the local Swift quality gate.

## Scope Boundaries

- This task does not add or change app functionality.
- This task does not rewrite the product roadmap beyond making it discoverable.
- This task does not revisit watchlist, setup, refresh, or packaging product
  decisions.
- This task does not create a broad documentation site.

## Key Decisions

- **Prefer removal for stale template docs:** The Swift iOS support notes are
  unrelated to Kubebar's current product direction, and Git history is enough
  preservation for this cleanup.
- **Keep README concise:** README should orient a contributor and point to
  deeper docs, not duplicate the roadmap.
- **Keep architecture docs product-specific:** The architecture entry point
  should name the existing Kubebar notes and avoid generic placeholder text.

## Dependencies / Assumptions

- The current implementation already includes setup-related views and live menu
  wiring, based on `Kubebar/Views/SetupView.swift`,
  `Kubebar/Views/MenuBarRootView.swift`, and `Kubebar/MenuBarViewModel.swift`.
- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md` is the current roadmap
  entry point for Kubebar.

## Next Steps

-> `/ce:plan` for structured implementation planning
