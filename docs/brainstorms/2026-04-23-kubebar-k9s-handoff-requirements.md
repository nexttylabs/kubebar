---
date: 2026-04-23
topic: kubebar-k9s-handoff
---

# Kubebar k9s Handoff Requirements

## Problem Frame

Kubebar helps a daily Kubernetes operator notice when a watched target needs
attention. Today, the next step is manual: open `k9s`, choose the right context,
and navigate back to the relevant namespace before investigating.

This feature should reduce that handoff friction without changing Kubebar's
role. Kubebar remains the glanceable status tool. `k9s` remains the deeper
debugging tool.

## Requirements

**Handoff Entry**
- R1. Kubebar must provide an `Open in k9s` action for watched targets
  whose current state is `Watch` or `Bad`.
- R2. The action must appear in the Overview top status short detail when that
  status is driven by an abnormal watched target. It must be a deliberate
  button-style action, not an automatic launch or a primary row click.
- R3. Kubebar must not show this action for healthy watched targets, setup states,
  empty watchlist states, or any stale display state where the issue may no
  longer be current.
- R4. The first version of this handoff must focus on watched targets, not
  Recent Warnings, node rows, or a global context launcher.
- R5. Kubebar must only show the action when the app-owned context and watched
  target's namespace are both known. If either value is unavailable, the detail
  view must explain that `k9s` cannot be opened for that target.

**Handoff Behavior**
- R6. Activating `Open in k9s` must open the user's local `k9s` in the same
  app-owned Kubernetes context that Kubebar is displaying.
- R7. The handoff must land in the watched target's namespace. Namespace-level
  targeting is the required baseline; exact workload or pod positioning is not
  required for this version unless planning proves it can be done safely without
  adding deeper troubleshooting behavior to Kubebar.
- R8. While the handoff is opening, Kubebar must provide brief feedback so the
  user does not mistake a delayed launch for a dead action.
- R9. If `k9s` cannot be opened, Kubebar must show a clear failure message that
  identifies the intended context and namespace.
- R10. The handoff must not silently fall back to the terminal's current
  Kubernetes context.

**Product Boundaries**
- R11. Kubebar must not embed a terminal, stream logs, show raw command output,
  or add a troubleshooting console as part of this feature.
- R12. Kubernetes watch streams remain out of scope for this feature; fixed
  polling should continue to prove the daily status loop first.
- R13. Multi-cluster switching remains out of scope. The handoff uses the
  context Kubebar already owns and displays.
- R14. The menu must remain glanceable after this action is added; the handoff
  must not crowd out the primary watched target state or reason.
- R15. The action must remain reachable through keyboard navigation and must
  have accessibility text that names the external action and target namespace.

## Success Criteria

- From an abnormal watched target, the user can open `k9s` for the same
  context and namespace with one deliberate action.
- Healthy, stale, setup, and empty-watchlist states do not offer a misleading
  handoff.
- Watched targets without a known context or namespace do not offer a broken
  handoff.
- Missing or unavailable `k9s` produces an understandable message rather than a
  silent failure.
- A slow launch shows feedback before success or failure.
- Keyboard and screen-reader users can reach and understand the handoff action.
- Kubebar still reads as a lightweight status instrument, not a replacement for
  `k9s`.

## Scope Boundaries

- No embedded terminal.
- No logs view.
- No command transcript display.
- No full troubleshooting surface inside the menu.
- No Recent Warnings handoff in this version.
- No node-level handoff in this version.
- No multi-cluster switching UI.
- No Kubernetes watch-stream behavior.

## Key Decisions

- **Start with watched target handoff:** This matches Kubebar's watchlist-first
  product value and avoids turning every warning or node row into a launcher.
- **Open directly, without a confirmation step:** The feature's value is
  reducing friction from signal to investigation. Failure states can explain
  what went wrong when local `k9s` is unavailable.
- **Use namespace-level targeting as the baseline:** It is enough to place the
  operator in the right context and namespace without requiring Kubebar to own
  deeper `k9s` navigation semantics. Exact workload targeting can be considered
  during planning only if it stays within the same shallow handoff boundary.
- **Keep stale data from launching investigations:** Stale state must not look
  current, and a handoff from stale data could point the operator at an outdated
  problem.
- **Place the action in Overview top status detail:** The entry stays close to
  the abnormal signal that made the operator open Kubebar, while keeping the
  visible top row focused on state and reason.

## Alternatives Considered

| Option | Pros | Cons | Decision |
| --- | --- | --- | --- |
| Keep as backlog only | Lowest scope risk | Does not reduce daily handoff friction | Rejected |
| Recent Warnings handoff | Useful for event-driven investigation | Less aligned with watchlist-first value | Deferred |
| Global context launcher | Simple and low risk | Does not help locate the watched issue | Rejected for first version |
| Copy command instead of opening `k9s` | Transparent and safe | Adds manual friction | Rejected |
| Open plus copy options | Flexible fallback | Adds extra UI weight | Deferred |

## Dependencies / Assumptions

- The user has local Kubernetes access already configured for `kubectl`.
- `k9s` is an optional local tool; Kubebar must handle it being absent.
- The display model can identify the abnormal watched target, app-owned
  context, and namespace needed for the handoff.

## Outstanding Questions

### Deferred to Planning
- [Affects R6-R10][Technical] What is the simplest macOS-safe way to open the
  user's local `k9s` with an explicit context and namespace?
- [Affects R9][Technical] How should Kubebar detect and message unavailable
  `k9s` without exposing command transcripts?
- [Affects R8][Technical] What short in-progress state is enough for a slow
  external launch?
- [Affects R15][Technical] What exact keyboard focus order and accessibility
  label should the Overview top status detail use?

## Next Steps

-> `/ce:plan` for structured implementation planning
