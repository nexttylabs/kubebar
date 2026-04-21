# Phase 04: CodexBar-Inspired Menu Reliability and Freshness - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning
**Source:** `$gsd-plan-phase` after CodexBar comparison

<domain>

## Phase Boundary

This phase adapts the useful design logic from CodexBar into Kubebar without
turning Kubebar into CodexBar or a Kubernetes dashboard.

The phase delivers:
- A local run script that builds, tests, relaunches, and verifies the menu bar
  app process.
- Testable setup/menu state so first-use regressions are caught before manual
  testing.
- Refresh cadence and freshness behavior that make current, stale, and failed
  states predictable.
- Clearer menu bar icon semantics, privacy docs, and an operator-facing QA
  checklist.

This phase does not deliver:
- Migration from `MenuBarExtra.window` to a full AppKit `NSStatusItem`.
- CodexBar's provider registry, usage providers, widgets, update flow, cookies,
  keychain access, or bundled CLI.
- Full issue #4 warning/event reason expansion.
- Local distribution, notarization, Sparkle, or `Open in k9s` handoff.

</domain>

<decisions>

## Implementation Decisions

### Preserve Kubebar's Product Shape

- Keep the first screen watchlist-first.
- Keep the menu bar icon categorical: `OK`, `Watch`, `Bad`, or `Stale`.
- Keep stale data visible only when it is clearly marked stale.
- Keep app-owned saved context as the source of truth.
- Keep `kubectl` reads behind injectable boundaries.

### Adapt CodexBar's Best Lessons

- Treat the menu bar app as an instrument: the icon gives the first signal, the
  menu explains it, and actions close the loop.
- Add a build-and-run script because menu bar bugs often survive unit tests.
- Move setup/menu transitions into small value models where possible.
- Make refresh cadence and last-updated state visible rather than implicit.
- Use docs to state privacy and read-boundary guarantees clearly.

### the agent's Discretion

- Exact model names may change if the same boundaries are preserved.
- The launch script may use `open`, `osascript`, `pgrep`, or other standard
  macOS tools as long as it avoids broad destructive process matching.
- UI copy may be adjusted for clarity, but the product meaning must stay the
  same.

</decisions>

<canonical_refs>

## Canonical References

Downstream agents MUST read these before implementing.

### Product Direction

- `AGENTS.md` - repo rules and Kubebar product guardrails.
- `docs/plans/2026-04-19-002-kubebar-product-roadmap.md` - issue ordering and
  completion bar.
- `docs/brainstorms/2026-04-19-kubebar-watchlist-first-requirements.md` -
  original watchlist-first requirements.

### Architecture

- `docs/architecture/system-overview.md` - runtime flow and component ownership.
- `docs/architecture/runtime-invariants.md` - icon, freshness, config, and
  stale-state invariants.
- `.planning/codebase/ARCHITECTURE.md` - codebase map of current architecture.
- `.planning/codebase/TESTING.md` - available quality gates and test shape.

### Current Phase Inputs

- `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-RESEARCH.md`
  - CodexBar comparison and lessons.
- `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-PATTERNS.md`
  - local code patterns to reuse.

### Prior Phase

- `.planning/phases/03-complete-first-use-setup-and-watchlist-editing/03-CONTEXT.md`
  - setup/watchlist decisions.
- `.planning/phases/03-complete-first-use-setup-and-watchlist-editing/03-VERIFICATION.md`
  - issue #3 verification state and remaining manual UAT context.

</canonical_refs>

<specifics>

## Specific Ideas

- Add a `scripts/compile-and-run.sh` command similar in spirit to CodexBar's
  run loop: build/test, stop stale app process, launch the built `.app`, and
  confirm it is running.
- Add a pure setup/menu runtime state model so first launch, partial config,
  edit watchlist, and target-loading failure behavior are covered by tests.
- Use existing `AppConfig.refreshIntervalSeconds` instead of replacing config
  storage.
- Show refresh cadence and freshness in the menu without making the menu feel
  like a dashboard.
- Add or update UAT docs for menu states that cannot be fully proven by unit
  tests.

</specifics>

<deferred>

## Deferred Ideas

- AppKit `NSStatusItem` migration.
- WidgetKit, update checks, provider registry, and usage-provider concepts.
- Distribution packaging and notarization.
- Full event/actionable reason expansion for issue #4.
- Deep debugging handoff such as `Open in k9s`.

</deferred>

---

*Phase: 04-codexbar-inspired-menu-reliability-and-freshness*
*Context gathered: 2026-04-21*
