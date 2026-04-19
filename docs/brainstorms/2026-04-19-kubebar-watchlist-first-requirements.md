---
date: 2026-04-19
topic: kubebar-watchlist-first
---

# Kubebar Watchlist-First Requirements

## Problem Frame

`Kubebar` is a native macOS menu bar app for one person who watches a Kubernetes cluster every day and wants to know, at a glance, whether the cluster is stable enough right now.

The current alternative is opening `k9s`. That works, but it asks for more attention than this use case needs. The first version should answer three questions quickly:

1. Are nodes healthy enough right now?
2. Are the workloads I care about healthy enough right now?
3. Are there current warning events that need attention?

The product should feel like a small personal instrument, not a mini dashboard and not a `k9s` replacement.

## Visual Aid

```text
Menu bar icon
  -> Current context + health sentence
  -> Compact counters (nodes / pods / warning events)
  -> Watchlist (3-5 items visible)
       -> Item detail submenu
  -> View all tracked
  -> Recent warning events
  -> Node details
  -> Actions (Refresh now / Edit watchlist)
```

## Requirements

**Core awareness**
- R1. The menu bar icon must communicate one of four states: `OK`, `Watch`, `Bad`, or `Stale`.
- R2. Opening the menu must show the current saved cluster context and a one-line health summary before any lower-level details.
- R3. The first screen must include compact top-level counts for nodes, pods, and warning events.
- R4. The menu must help the user identify what needs attention in under a few seconds, without opening another tool first.

**Watchlist-first behavior**
- R5. The primary content area of the first screen must be a personal watchlist of namespaces or workloads the user explicitly chose.
- R6. The first screen must show only `3-5` tracked items so the menu stays readable at a glance.
- R7. If more tracked items exist, the remaining items must live behind a secondary entry such as `View all tracked`.
- R8. Each tracked row must show a short reason when unhealthy, such as restarting pods, pending pods, or recent warnings.
- R9. Selecting a tracked item must open a short detail view that confirms the problem without turning into a full troubleshooting console.

**Trust, failure, and freshness**
- R10. The app must never make stale data look healthy or current.
- R11. If refresh fails, the menu must keep the last known data visible only when it is clearly marked `Stale`.
- R12. A stale state must show when the last successful update happened, why refresh failed when known, and a direct `Retry now` action.
- R13. Warning and failure states must not rely on color alone; wording or symbols must also carry the meaning.

**First-use and configuration**
- R14. First launch must open in an explicit setup state rather than an empty or fake healthy state.
- R15. The app must save and use its own chosen cluster context instead of depending on whatever the terminal is currently pointed at.
- R16. The first-use flow must guide the user through choosing a small watchlist of namespaces or workloads.
- R17. An empty watchlist must be treated as a real product state with a clear next action to add tracked items.

**Interaction and reading comfort**
- R18. The dropdown must feel like a disciplined menu bar utility, not a small dashboard made of cards or widgets.
- R19. The first screen must prioritize typography, ordering, and spacing over decorative UI.
- R20. Long object names must truncate consistently so the menu remains scannable during daily use.
- R21. Keyboard navigation must work across top-level rows and submenus.

## Success Criteria

- The icon alone lets the user tell whether the cluster is healthy, shaky, broken, or stale.
- Opening the menu answers “what is wrong?” fast enough that the user can decide whether deeper debugging is needed.
- The user can set up a useful watchlist on first use without reading separate documentation.
- A failed refresh is obvious and never mistaken for a healthy state.
- The tool is simple enough to stay open every day beside normal cluster work.

## Scope Boundaries

- Version 1 is not a replacement for `k9s`.
- Version 1 does not try to become a full troubleshooting surface.
- Version 1 does not auto-generate a watchlist on the user’s behalf.
- Version 1 does not show an unlimited scrolling primary menu.
- Version 1 does not support multi-cluster switching inside the app.
- Version 1 does not optimize for teams or shared operational workflows.

## Key Decisions

- **Watchlist first:** The user’s chosen workloads come before global detail because that is the product’s main value.
- **Saved context inside the app:** This keeps the product trustworthy and avoids ambiguity about what cluster the menu represents.
- **Explicit setup state on first launch:** “Not configured” must never look like “healthy.”
- **Short detail views only:** The app should confirm problems quickly, then let deeper investigation happen elsewhere.
- **Extreme visual restraint:** The menu should feel close to a native macOS utility and avoid generic dashboard patterns.
- **Keep old data only when clearly stale:** This preserves usefulness during short failures without pretending the data is current.

## Dependencies / Assumptions

- The user already has working Kubernetes access on the Mac they use for cluster work.
- The first version is aimed at a single daily operator rather than a broad audience.
- The product will be judged mainly on trust, speed of orientation, and how often it stays open during normal work.

## Outstanding Questions

### Deferred to Planning
- [Affects R1-R4][Needs research] What exact icon treatment best separates `OK`, `Watch`, `Bad`, and `Stale` while staying readable in the macOS menu bar?
- [Affects R11-R12][Needs research] What refresh cadence and timeout behavior keep the menu trustworthy without making the app feel noisy?
- [Affects R14-R17][Technical] What is the simplest first-use flow that lets the user pick a saved context and initial watchlist without adding setup friction?

## Next Steps

-> `/ce:plan` for structured implementation planning
