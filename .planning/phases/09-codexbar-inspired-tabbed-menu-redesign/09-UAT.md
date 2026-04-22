---
status: pending-human-verification
phase: 09-codexbar-inspired-tabbed-menu-redesign
source:
  - 09-UI-SPEC.md
  - 09-VALIDATION.md
  - 09-01-SUMMARY.md
  - 09-02-SUMMARY.md
  - 09-03-SUMMARY.md
  - 09-04-PLAN.md
  - 09-04-SUMMARY.md
started: 2026-04-22T07:05:48Z
updated: 2026-04-22T09:17:43Z
---

# Phase 09 UAT

Phase 09 visible menu behavior still needs human confirmation because local automation can build and launch the macOS menu bar app, but cannot reliably inspect the opened `MenuBarExtra.window` menu, native Settings window, keyboard focus traversal, or Quit flow.

Evidence in this file is intentionally limited to safe summaries, source-backed expectations, app path/PID references when available, and pending human-verification notes. Do not add raw command transcripts, kubeconfig paths, token-like values, full JSON, or unredacted cluster details.

## UAT Scenarios

| Scenario | Requirement | Status | Steps | Expected Result | Evidence | Limitations |
| --- | --- | --- | --- | --- | --- | --- |
| Open menu from OK icon | REQ-09-01, REQ-09-03, REQ-09-10 | pending-human-verification | Launch Kubebar with an OK display state, open the menu bar item, and inspect Overview. | Overview is selected. `OK` text, symbol, short reason, counters, and `Watching` are visible. Healthy watched rows are capped at 3 by default. Meaning is not color-only. | Plan 01 covers OK display mapping. Plan 04 covers healthy watched cap and `Watching` copy in tests/source checks. Visible opened-menu evidence is still required. | Automation can launch the app but cannot reliably open and inspect the menu. Use app-owned fixture names or redact real cluster names. |
| Open menu from Watch icon | REQ-09-01, REQ-09-03, REQ-09-06, REQ-09-10 | pending-human-verification | Launch Kubebar with a Watch display state, open the menu bar item, and inspect Overview. | Overview is selected. `Watch` text, symbol, and reason are visible; attention rows appear before counters; warning or unavailable context is explicit and not color-only. | Plan 01 covers Watch reasons, unavailable warning events, and event summary behavior. Plan 04 covers attention-first watched ordering. Visible opened-menu evidence is still required. | Requires a controllable Watch state in the visible app or a safe fixture build. |
| Open menu from Bad icon | REQ-09-01, REQ-09-03, REQ-09-05, REQ-09-10 | pending-human-verification | Launch Kubebar with a Bad display state, open the menu bar item, and inspect Overview plus reachable details. | Overview is selected. The bad reason is visible; watched rows and details remain reachable; attention rows may show up to 5 rows before overflow. Meaning is not color-only. | Plan 01 covers unhealthy watched rows. Plan 04 covers `Bad`, `Watch`, `Stale`, `OK` priority ordering, attention cap, hidden count, and conditional detail disclosure. Visible opened-menu evidence is still required. | Requires a safe Bad fixture or redacted real-cluster observation. |
| Open menu from Stale icon | REQ-09-01, REQ-09-03, REQ-09-04, REQ-09-05, REQ-09-06 | pending-human-verification | Launch Kubebar with stale data, open the menu bar item, and inspect Overview plus resource tabs. | Overview is selected. Stale banner appears directly after status; stale node, pod, and event content does not look healthy or current; stale watched rows rank before healthy rows. | Plan 01 covers stale display, stale banner copy, and previous-data retention. Plan 04 covers stale watched priority. Visible opened-menu evidence is still required. | Requires a stale state that does not expose sensitive cluster names. |
| Auto-height menu avoids unnecessary scrollbars | REQ-09-01, REQ-09-03, REQ-09-09 | pending-human-verification | Launch Kubebar, open healthy and common warning Overview states, and inspect menu height, selected-tab content, and footer placement. | Normal Overview content is not forced into a short fixed scroll area. The menu fits content naturally where possible; only selected tab content scrolls after the maximum height is reached; the footer remains visible. | Plan 04 source checks cover removal of forced minimum content height, selected-tab scroll containment, hidden scroll indicators, and visible app launch with PID `46332`. Visible scrollbar/footer observation is still required. | Automation can launch but cannot reliably inspect the opened menu's scrollbar state. |
| Footer language | REQ-09-07, REQ-09-08, REQ-09-09, REQ-09-10 | pending-human-verification | Open the menu and inspect footer text, timer help, and accessibility labels. | Footer visible text says `Last checked {age}`. Timer help/accessibility says `Refresh every {cadence}`. Redundant visible cadence text is not shown. Refresh, settings, and quit remain icon controls. | Plan 04 source checks cover `Last checked`, `Refresh every`, and absence of `Refresh cadence:`/`Updated (` copy. Visible tooltip/accessibility observation is still required. | Tooltip and accessibility inspection require human or dedicated native UI tooling. |
| Switch tabs without refresh | REQ-09-01, REQ-09-02, REQ-09-04, REQ-09-05, REQ-09-06 | pending-human-verification | Open the menu, switch `Overview`, `Nodes`, `Pods`, and `Events`, then watch for refresh indicators or changed timestamps. | Selected content changes by tab. Switching tabs does not trigger refresh, `kubectl` reads, or timestamp changes by itself. | Plan 01 source checks found tabs are local UI state with no refresh hook. Human menu observation is still required for visible content switching. | Automation cannot reliably click through menu tabs. |
| Reopen menu resets to Overview | REQ-09-01, REQ-09-02 | pending-human-verification | Open the menu, switch to a non-Overview tab, close the menu, reopen it. | The selected tab resets to `Overview` on reopen and is not persisted as app config. | Plan 01 implementation records local tab state and Overview reset behavior. Human menu observation is still required. | `MenuBarExtra.window` reopen behavior is app-shell behavior and needs visible confirmation. |
| Empty Watching opens Settings path | REQ-09-03, REQ-09-07, REQ-09-10 | pending-human-verification | Launch with a configured context and empty watched targets, open the menu, then activate the empty-state Settings path. | Empty `Watching` is shown as a configuration state, not healthy cluster content. Copy says `No tracked workloads yet` and points to Settings. | Plan 02 source and tests cover compact Settings prompt and Settings preparation. Plan 04 source checks confirm `Watching` copy. Visible opened-menu evidence is still required. | Requires a safe empty-watched-target fixture or redacted local config. |
| Settings... opens independent dialog/window | REQ-09-07, REQ-09-09 | pending-human-verification | Open the menu and activate `Settings...`. | A separate native Settings dialog/window opens. Settings is not a tab and does not replace selected menu content as the normal edit path. | Plan 02 automated tests cover Settings preparation and source checks cover no embedded setup body. Human Settings-window observation is still required. | Automation cannot reliably inspect native Settings presentation from the opened menu. |
| Quit Kubebar exits and preserves config | REQ-09-08, REQ-09-09 | pending-human-verification | Record saved context, watched targets, and refresh cadence; open the menu; activate `Quit Kubebar`; relaunch and compare saved config. | Kubebar exits. Saved context, watched targets, and refresh cadence are unchanged after relaunch. | Plan 02 source checks verify Quit calls app termination only. Human Quit-flow and config-preservation evidence is still required. | Do not paste local config paths or raw config contents. Summarize only preserved fields. |
| Keyboard navigation reaches tabs refresh settings quit details and sections | REQ-09-01, REQ-09-07, REQ-09-08, REQ-09-09 | pending-human-verification | With Full Keyboard Access enabled if needed, open the menu and traverse tabs, refresh cadence, `Retry now`, `Settings...`, `Quit Kubebar`, watched details, warning events, node summaries, pod summaries, and Settings fields. | Native keyboard traversal reaches all required controls and disabled states remain visible and understandable. Rows without extra detail do not show an unnecessary disclosure target. | Native SwiftUI controls and shortcuts are present in source. Plan 04 tests cover `hasExpandedContent`. Human keyboard traversal evidence is still required. | Keyboard traversal depends on macOS focus settings and cannot be reliably proven by current automation. |
| Long names use middle truncation with full help/accessibility | REQ-09-10, REQ-09-03, REQ-09-04, REQ-09-05, REQ-09-06 | pending-human-verification | Use long context, namespace, workload, pod, node, and event object names; inspect Overview and resource tabs; check hover help or accessibility labels. | Long values stay one line with middle truncation. Full values remain available through help/accessibility labels without exposing command transcripts or JSON. | Plan 01 and existing view patterns preserve `.truncationMode(.middle)`, help text, and accessibility labels for display names. Visible and accessibility evidence is still required. | Use fixture names or redacted observations; do not commit sensitive real cluster identifiers. |

## Human Evidence Needed

| Area | Needed Evidence | Safe Recording Rule |
| --- | --- | --- |
| Opened menu states | Screenshot path or concise human observation for OK, Watch, Bad, and Stale states. | Use app-owned fixture names or redact real context/object names. |
| Auto-height and footer | Observation that normal Overview states avoid unnecessary visible scrollbars, footer stays visible, and footer copy reads `Last checked`. | Record behavior only; avoid real cluster identifiers in screenshots or text. |
| Tab switching and reopen reset | Observation that tab content changes without refresh and reopen returns to Overview. | Record only behavior, not command output. |
| Settings | Observation that `Settings...` opens a separate Settings dialog/window. | Do not include local filesystem paths unless they are the built app path. |
| Quit | Observation that app exits and saved config fields remain unchanged after relaunch. | Summarize preserved field names only. |
| Keyboard and long names | Observation that focus traversal and truncation behave as expected. | Avoid screenshots or text containing sensitive cluster identifiers. |

## Visible App Smoke Evidence

| Check | Result | Evidence | Limitation |
| --- | --- | --- | --- |
| `./scripts/compile-and-run.sh` | pass | Built and launched `DerivedData/Build/Products/Debug/Kubebar.app` with PID `46332`; QA state reported `live`. | This confirms launch only. It does not inspect the opened menu, Settings window, keyboard traversal, or Quit behavior. |

## Requirement Coverage

| Requirement | UAT Coverage |
| --- | --- |
| REQ-09-01 | OK/Watch/Bad/Stale open-menu rows, auto-height row, tab switching row, reopen reset row, keyboard row. |
| REQ-09-02 | Tab switching without refresh row and reopen reset row. |
| REQ-09-03 | Overview state rows, auto-height row, empty `Watching` row, long-name row. |
| REQ-09-04 | Stale row, tab switching row, long-name row. |
| REQ-09-05 | Bad row, stale row, tab switching row, long-name row. |
| REQ-09-06 | Watch row, stale row, tab switching row, long-name row. |
| REQ-09-07 | Empty `Watching` Settings path, Settings dialog/window row, footer language row, keyboard row. |
| REQ-09-08 | Footer language row, Quit row, and keyboard row. |
| REQ-09-09 | Auto-height row, footer language row, Settings, Quit, and keyboard rows. |
| REQ-09-10 | Status rows, footer language row, empty `Watching` row, and long-name row. |
