# Phase 06: Polish Menu Bar Icon States and Keyboard Navigation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log preserves the alternatives considered.

**Date:** 2026-04-21
**Phase:** 06-polish-menu-bar-icon-states-and-keyboard-navigation
**Areas discussed:** Menu bar icon states, Non-color status expression, Menu reading experience, Long-name truncation, Keyboard navigation and verification

---

## Menu Bar Icon States

| Option | Description | Selected |
| --- | --- | --- |
| All states use status symbols | `OK` also uses a health symbol; brand logo is not the healthy state. | no |
| OK uses brand logo, other states use status symbols | Healthy state keeps the brand logo; warning and failure states use explicit symbols. | yes |
| Brand logo plus status marker | Keep brand logo and add state meaning. | no |

**User's choice:** OK uses the brand logo; Watch, Bad, and Stale use status symbols.
**Notes:** Preserve the current brand-forward healthy state.

| Option | Description | Selected |
| --- | --- | --- |
| Reuse current symbols | `Watch = exclamationmark.triangle`, `Bad = xmark.octagon`, `Stale = clock.badge.exclamationmark`. | yes |
| Use a circle-based set | Use a more uniform symbol family. | no |
| Choose a stronger new symbol set | Prioritize maximum visual difference. | no |

**User's choice:** Reuse the current symbol set.
**Notes:** Planning should polish and verify this set rather than reselect icons.

| Option | Description | Selected |
| --- | --- | --- |
| Opened menu top clearly shows OK | Keep menu bar logo and confirm `OK` in the opened menu. | yes |
| Show OK text next to the menu bar logo | Make menu bar state text visible at all times. | no |
| Use checkmark for healthy state | Replace healthy logo with a health symbol. | no |

**User's choice:** Keep the menu bar logo, then show `OK` clearly at the top of the opened menu.
**Notes:** This avoids making the logo the only healthy-state signal.

---

## Non-Color Status Expression

| Option | Description | Selected |
| --- | --- | --- |
| Symbol + status text + short reason | State meaning is carried by more than color and includes the top reason. | yes |
| Symbol + status text | Clear but less explanatory for `Bad` or `Stale`. | no |
| Symbol-first with weak text | Visually lighter but weaker for accessibility and issue requirements. | no |

**User's choice:** Use symbol, status text, and a short reason.
**Notes:** Warning and failure states must not rely on color alone.

| Option | Description | Selected |
| --- | --- | --- |
| Top shows one most important reason | Keep top status fast to read; details remain below. | yes |
| Top shows 2-3 reasons | More complete but competes with watchlist-first. | no |
| Top shows state only | Minimal but less useful for bad or stale states. | no |

**User's choice:** Show only the single most important reason at the top.
**Notes:** Details stay in watchlist/detail, stale banner, and warning sections.

---

## Menu Reading Experience

| Option | Description | Selected |
| --- | --- | --- |
| Small native utility style | Tighten hierarchy, spacing, and typography without dashboard/card UI. | yes |
| Stronger visual sections | More separated areas, but risks dashboard feel. | no |
| More minimal menu | Hide lower-priority information, but weakens completed issue #4 value. | no |

**User's choice:** Reference CodexBar design.
**Notes:** Use CodexBar as a guide for a compact instrument-like menu: icon as first signal, opened menu as explanation, and native menu restraint. Do not copy CodexBar's provider/widget architecture.

| Option | Description | Selected |
| --- | --- | --- |
| Status summary + watchlist priority | Keep status and watchlist as the first reading path. | yes |
| Count priority | Make node, pod, and warning counts more prominent. | no |
| Exception priority | Move details earlier whenever warning/bad/stale exists. | no |

**User's choice:** Status summary plus watchlist priority.
**Notes:** Warning events and node details remain lower-priority sections.

| Option | Description | Selected |
| --- | --- | --- |
| Tighten but do not compress | Reduce extra spacing while keeping native readability. | yes |
| More compact | Fit more content but risk harder scanning and keyboard focus. | no |
| More spacious | Easier reading but weaker quick glance. | no |

**User's choice:** Tighten but do not compress.
**Notes:** Use native menu grouping, not cards.

---

## Long-Name Truncation

| Option | Description | Selected |
| --- | --- | --- |
| Preserve front and back with middle truncation | Keep environment/namespace context plus resource tail visible. | yes |
| Truncate only at the end | Simpler, but often hides the meaningful resource suffix. | no |
| Use multiple lines | Complete text, but unstable menu height. | no |

**User's choice:** Use middle truncation.
**Notes:** Kubernetes names often need both prefix and suffix to stay scannable.

| Option | Description | Selected |
| --- | --- | --- |
| Hover tooltip/accessibility full name | Keep visual row short while preserving full value. | yes |
| Detail area shows full name | More visible, but makes details heavier. | no |
| No full-name fallback | Simplest, but weak for similar long names. | no |

**User's choice:** Provide full names through hover tooltip and accessibility.
**Notes:** Do not clutter the primary menu.

| Option | Description | Selected |
| --- | --- | --- |
| Preserve tail differences | Resource-name suffixes often carry the distinguishing part. | yes |
| Fixed character-count truncation | Simple, but can cut away the important difference. | no |
| Solve only in detail | Primary list remains easy to misread. | no |

**User's choice:** Preserve tail differences.
**Notes:** Truncation should reduce the chance of confusing similar resources.

---

## Keyboard Navigation and Verification

| Option | Description | Selected |
| --- | --- | --- |
| Cover all major operations and expandable content | Setup, refresh, edit watchlist, details, warnings, and secondary sections are keyboard reachable. | yes |
| Cover only main buttons and setup | Lighter but incomplete for issue scope. | no |
| Rely on default accessibility only | Risky for disclosure groups, pickers, and button order. | no |

**User's choice:** Cover all major operations and expandable content.
**Notes:** Keyboard navigation includes setup, refresh, edit watchlist, watchlist detail, warning events, and secondary sections.

| Option | Description | Selected |
| --- | --- | --- |
| Automatic tests + manual QA document | Test deterministic state and document real menu keyboard QA. | yes |
| Automatic tests only | Clean but may miss real menu bar keyboard behavior. | no |
| Manual QA only | Fast but weak against regressions. | no |

**User's choice:** Use automatic tests plus manual QA documentation.
**Notes:** Existing test shape can cover state/model behavior; real menu interaction needs UAT.

| Option | Description | Selected |
| --- | --- | --- |
| Four states + setup/edit/refresh paths | Cover `OK`, `Watch`, `Bad`, `Stale`, setup, edit watchlist, and refresh enabled/disabled. | yes |
| Only icon/keyboard scope | Narrower, but misses state-content coupling. | no |
| Full daily loop | More complete, but belongs closer to issue #7. | no |

**User's choice:** Cover four states plus setup, edit watchlist, and refresh paths.
**Notes:** Full daily-loop operator QA remains deferred to issue #7.

---

## the agent's Discretion

- Exact truncation length.
- Exact helper or view names.
- Which keyboard checks are automated versus documented in UAT.
- Exact short status wording as long as the meaning stays locked.

## Deferred Ideas

- Full daily-loop operator QA belongs to GitHub issue #7.
- AppKit `NSStatusItem` migration remains deferred.
- Local distribution, notarization, and packaging remain deferred.
- Deep troubleshooting handoff such as `Open in k9s` remains deferred.
