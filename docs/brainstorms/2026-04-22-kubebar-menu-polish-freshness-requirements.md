---
date: 2026-04-22
topic: kubebar-menu-polish-freshness
---

# Kubebar Menu Polish and Freshness Requirements

## Problem Frame

Kubebar's menu should feel stable, compact, and trustworthy while operators move
between tabs. The current experience has a few rough edges: long Events content
can compete with the bottom action area, the tab bar needs more balanced
horizontal spacing, refresh cadence appears in the menu even though it belongs
in Settings, and the `Last checked 0s ago` text can remain visually stale after
time passes.

These fixes are small individually, but together they protect Kubebar's core
role as a glanceable menu bar status tool.

## Requirements

**Menu Frame and Footer**
- R1. The bottom action area must stay at the bottom of the menu for every tab,
  including Events.
- R2. Scrollable tab content must scroll above the bottom action area instead
  of pushing the actions out of view.
- R3. The footer must continue to show the latest checked time plus the primary
  actions for refresh, settings, and quit.

**Tab Bar Alignment**
- R4. The tab bar must have visually equal left and right spacing to the menu
  edges.
- R5. The tab bar must remain aligned with the rest of the menu content and not
  appear shifted toward one side.

**Refresh Cadence Placement**
- R6. Refresh cadence selection must be removed from the menu footer.
- R7. Refresh cadence selection must remain available in Settings.
- R8. Removing the menu cadence control must not change the saved cadence,
  automatic refresh interval, or setup/settings flow behavior.

**Last Checked Freshness**
- R9. `Last checked` text must update as time passes while the menu is open.
- R10. The freshness label must not stay stuck at `0s ago` after the first
  second has passed.
- R11. Updating the freshness label must not imply that new cluster data has
  been fetched.
- R12. Existing stale-data behavior must remain intact: old data still becomes
  visibly stale according to the saved refresh cadence.

## Success Criteria

- The Events tab can contain enough warning rows to require scrolling, and the
  bottom action area remains visible at the bottom.
- The segmented tab control appears horizontally balanced inside the menu.
- The menu footer no longer contains a refresh-cadence/timer control.
- Settings still exposes refresh cadence and saves it normally.
- After a successful refresh, `Last checked 0s ago` advances naturally without
  requiring another cluster refresh.
- No additional Kubernetes reads happen solely to update relative time text.

## Scope Boundaries

- No redesign of warning event row content.
- No change to the menu bar health categories: `OK`, `Watch`, `Bad`, and
  `Stale`.
- No removal of refresh cadence from Settings or persisted configuration.
- No new deep troubleshooting controls in the menu.
- No change to the meaning of stale data.

## Key Decisions

- **Keep cadence in Settings only:** Refresh cadence is a configuration choice,
  not a frequent menu action. Keeping it in Settings reduces footer clutter
  without removing capability.
- **Keep the footer fixed and scroll tab content:** Operators should not lose
  refresh, settings, or quit actions because one tab has a long list.
- **Treat freshness updates as display updates:** Relative time text should
  update independently of data refresh so the UI does not look frozen or falsely
  current.

## Outstanding Questions

### Resolve Before Planning

- None.

### Deferred to Planning

- [Affects R9-R12][Technical] Choose the lightest refresh-timer behavior that
  keeps `Last checked` accurate without unnecessary UI work.
- [Affects R1-R5][Technical] Confirm the exact height budget and spacing values
  against the existing menu layout.

## Next Steps

-> /ce:plan for structured implementation planning
