# Operator Verification

## Scope

This guide covers operator-facing checks for the menu states required by Phase 07. It verifies the real menu-bar app shell with deterministic QA states and does not replace the automated test suite.

## QA State Commands

- `./scripts/compile-and-run.sh --qa-state healthy`
- `./scripts/compile-and-run.sh --qa-state watch`
- `./scripts/compile-and-run.sh --qa-state bad`
- `./scripts/compile-and-run.sh --qa-state stale-refresh-failure`
- `./scripts/compile-and-run.sh --qa-state stale-age-out`
- `./scripts/compile-and-run.sh --qa-state first-use`
- `./scripts/compile-and-run.sh --qa-state empty-watchlist`
- `./scripts/compile-and-run.sh --qa-state kubectl-failure`
- `./scripts/compile-and-run.sh --qa-state metrics-unavailable`
- `./scripts/compile-and-run.sh --qa-state warning-heavy`

## Evidence Rules

Screenshots belong under `docs/assets/qa/` with these names:

- `phase-07-healthy.png`
- `phase-07-watch.png`
- `phase-07-bad.png`
- `phase-07-stale-refresh-failure.png`
- `phase-07-stale-age-out.png`
- `phase-07-first-use.png`
- `phase-07-empty-watchlist.png`
- `phase-07-kubectl-failure.png`
- `phase-07-metrics-unavailable.png`
- `phase-07-warning-heavy.png`

Evidence must not include raw command transcripts, tokens, kubeconfig paths, full JSON, or sensitive cluster details.

For all states, confirm the menu stays within the visible screen height. If a
tab has more rows than fit, the tab content should scroll inside the menu
instead of pushing the footer or lower rows off screen.

For all configured menu states, confirm the footer remains visible at the
bottom of the menu and contains only refresh, settings, and quit actions. The
refresh cadence picker belongs in Settings.

For Watch, Bad, Stale, `kubectl failure`, `metrics-unavailable`, and
`warning-heavy`, hover the Overview top status row. The visible status text
should stay short, and the hover text should explain the concrete safe reason
for that state.

## State Checklist

| State | Expected visible behavior | Evidence path |
|-------|---------------------------|---------------|
| Healthy | Menu shows OK with top status row, four Overview cards, neutral Recent Warnings, and Pods tab rows grouped by namespace with ready counts. | `docs/assets/qa/phase-07-healthy.png` |
| Watch | Menu shows Watch with a pinned BackOff warning row; Pods tab shows the watched Pod first with yellow dot, `0/1`, and gray issue text. | `docs/assets/qa/phase-07-watch.png` |
| Bad | Menu shows Bad and prioritizes the broken tracked target; Nodes tab shows a Not Ready node row, and Pods tab shows failed Pods first with red dots and issue text. | `docs/assets/qa/phase-07-bad.png` |
| Stale refresh failure | Menu shows Stale while preserving last known top row and cards with stale marking. | `docs/assets/qa/phase-07-stale-refresh-failure.png` |
| Stale age-out | Menu shows Stale because the last successful refresh is too old and cards are visibly stale. | `docs/assets/qa/phase-07-stale-age-out.png` |
| first-use | Menu shows setup before any saved context exists. | `docs/assets/qa/phase-07-first-use.png` |
| empty-watchlist | Menu shows setup because the QA fixture context has no selected namespaces. | `docs/assets/qa/phase-07-empty-watchlist.png` |
| kubectl failure | Menu shows Stale with a safe failure message and retained prior status. | `docs/assets/qa/phase-07-kubectl-failure.png` |
| metrics-unavailable | Menu keeps OK cluster status while CPU and Memory cards show unavailable metrics; Nodes tab keeps rows visible with `-` resource values, and Pods tab still shows watched Pods. | `docs/assets/qa/phase-07-metrics-unavailable.png` |
| warning-heavy | Menu shows capped Recent Warnings with the pinned tracked warning first, repeat count visible, message secondary, and overflow left for Events; Events tab scrolls above the footer, the footer remains visible with refresh/settings/quit only, and Pods tab keeps attention rows before ready rows. | `docs/assets/qa/phase-07-warning-heavy.png` |

## Keyboard Check

For Overview, confirm native keyboard focus reaches the top status row, Nodes,
Pods, CPU, Memory, visible `Recent Warnings` rows, and any warning overflow
affordance in that order. Keep this as `pending-human-verification` unless the
menu was actually opened and traversed.

## Recent Warnings Check

For warning rows, confirm the row reads as reason first, then affected object,
age/repeat count, and secondary message. Tracked-object warnings must be
recognizable without the word `Watching`. Empty, unavailable, and overflow
states must be distinct.

## Menu Footer and Freshness Check

For the footer, confirm refresh, settings, and quit remain reachable after
switching between Overview, Nodes, Pods, and Events. The tab bar should have
equal left and right spacing. After a fresh refresh, `Last checked 0s ago`
should advance as time passes without pressing refresh again.

## Overview Status Hover Check

For the Overview top status row, confirm hover/help text is more specific than
the visible one-line status when the state needs attention. It should name the
affected object or explain the stale/unavailable reason, and it must not expose
raw command output, kubeconfig paths, full JSON, or tokens.

## Nodes Tab Check

For the Nodes tab, confirm rows show node name, readiness, CPU, and Memory.
Not Ready rows must appear before Ready rows, use a non-color-only error cue,
and show a one-line issue description. In the metrics-unavailable state, node
rows should remain visible while CPU and Memory show `-`. If the node list is
taller than the menu, confirm the rows remain reachable by scrolling.

## Pods Tab Check

For the Pods tab, confirm rows are grouped by namespace. Each row should show a
status dot, Pod name, ready/all count, and a one-line gray issue description
when the Pod needs attention. Attention rows must appear before ready rows in a
namespace. If there are more Pod rows than fit, only the Pod item list should
scroll vertically while the Pod readiness summary stays visible. In the
metrics-unavailable state, Pod rows should remain visible.

## When To Mark pending-human-verification

Use `pending-human-verification` when screenshots are blocked, the menu cannot be opened during automation, or visible behavior has not been personally checked. Keep the row pending until a screenshot or equivalent human-visible record exists.
