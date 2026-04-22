---
status: pending-human-verification
phase: 09-codexbar-inspired-tabbed-menu-redesign
source:
  - 09-UI-SPEC.md
  - 09-VALIDATION.md
  - 09-01-SUMMARY.md
  - 09-02-SUMMARY.md
started: 2026-04-22T07:05:48Z
updated: 2026-04-22T07:07:45Z
---

# Phase 09 UAT

Phase 09 visible menu behavior still needs human confirmation because the local automation can build and launch the macOS menu bar app, but cannot reliably inspect the opened `MenuBarExtra.window` menu, native Settings window, keyboard focus traversal, or Quit flow.

Evidence in this file is intentionally limited to safe summaries, source-backed expectations, app path/PID references when available, and pending human-verification notes. Do not add raw command transcripts, kubeconfig paths, token-like values, full JSON, or unredacted cluster details.

## UAT Scenarios

| Scenario | Requirement | Status | Steps | Expected Result | Evidence | Limitations |
| --- | --- | --- | --- | --- | --- | --- |
| Open menu from OK icon | REQ-09-01, REQ-09-03, REQ-09-10 | pending-human-verification | Launch Kubebar with an OK display state, open the menu bar item, and inspect the first visible tab. | Overview is selected. `OK` text, symbol, short reason, counters, and the watchlist-first section are visible. Meaning is not color-only. | Plan 01 automated tests cover OK display mapping and watchlist caps. Visible opened-menu screenshot or human observation is still required. | Automation can launch the app but cannot reliably open and inspect the menu. Use app-owned fixture names or redact real cluster names. |
| Open menu from Watch icon | REQ-09-01, REQ-09-03, REQ-09-06, REQ-09-10 | pending-human-verification | Launch Kubebar with a Watch display state, open the menu bar item, and inspect Overview. | Overview is selected. `Watch` text, symbol, and reason are visible; warning or unavailable context is explicit and not color-only. | Plan 01 automated tests cover Watch reasons, unavailable warning events, and event summary behavior. Visible opened-menu evidence is still required. | Requires a controllable Watch state in the visible app or a safe fixture build. |
| Open menu from Bad icon | REQ-09-01, REQ-09-03, REQ-09-05, REQ-09-10 | pending-human-verification | Launch Kubebar with a Bad display state, open the menu bar item, and inspect Overview plus reachable details. | Overview is selected. The bad reason is visible; watchlist rows and details remain reachable. Meaning is not color-only. | Plan 01 automated tests cover attention ordering and unhealthy watchlist rows. Visible opened-menu evidence is still required. | Requires a safe Bad fixture or redacted real-cluster observation. |
| Open menu from Stale icon | REQ-09-01, REQ-09-03, REQ-09-04, REQ-09-05, REQ-09-06 | pending-human-verification | Launch Kubebar with stale data, open the menu bar item, and inspect Overview plus resource tabs. | Overview is selected. Stale banner appears directly after status; stale node, pod, and event content does not look healthy or current. | Plan 01 automated tests cover stale display, stale banner copy, and previous-data retention. Visible opened-menu evidence is still required. | Requires a stale state that does not expose sensitive cluster names. |
| Switch tabs without refresh | REQ-09-01, REQ-09-02, REQ-09-04, REQ-09-05, REQ-09-06 | pending-human-verification | Open the menu, switch `Overview`, `Nodes`, `Pods`, and `Events`, then watch for refresh indicators or changed timestamps. | Selected content changes by tab. Switching tabs does not trigger refresh, `kubectl` reads, or timestamp changes by itself. | Plan 01 source checks found tabs are local UI state with no refresh hook. Human menu observation is still required for visible content switching. | Automation cannot reliably click through menu tabs. |
| Reopen menu resets to Overview | REQ-09-01, REQ-09-02 | pending-human-verification | Open the menu, switch to a non-Overview tab, close the menu, reopen it. | The selected tab resets to `Overview` on reopen and is not persisted as app config. | Plan 01 implementation records local tab state and Overview reset behavior. Human menu observation is still required. | `MenuBarExtra.window` reopen behavior is app-shell behavior and needs visible confirmation. |
| Empty watchlist opens Settings path | REQ-09-03, REQ-09-07, REQ-09-10 | pending-human-verification | Launch with a configured context and empty watchlist, open the menu, then activate the empty-state Settings path. | Empty watchlist is shown as a configuration state, not healthy cluster content. Copy says `No tracked workloads yet` and points to Settings. | Plan 02 source and tests cover the compact Settings prompt and Settings preparation. Visible opened-menu evidence is still required. | Requires a safe empty-watchlist fixture or redacted local config. |
| Settings... opens independent dialog/window | REQ-09-07, REQ-09-09 | pending-human-verification | Open the menu and activate `Settings...`. | A separate native Settings dialog/window opens. Settings is not a tab and does not replace selected menu content as the normal edit path. | Plan 02 automated tests cover Settings preparation and source checks cover no embedded setup body. Human Settings-window observation is still required. | Automation cannot reliably inspect native Settings presentation from the opened menu. |
| Quit Kubebar exits and preserves config | REQ-09-08, REQ-09-09 | pending-human-verification | Record saved context, watchlist, and refresh cadence; open the menu; activate `Quit Kubebar`; relaunch and compare saved config. | Kubebar exits. Saved context, watchlist, and refresh cadence are unchanged after relaunch. | Plan 02 source checks verify Quit calls app termination only. Human Quit-flow and config-preservation evidence is still required. | Do not paste local config paths or raw config contents. Summarize only preserved fields. |
| Keyboard navigation reaches tabs refresh settings quit details and sections | REQ-09-01, REQ-09-07, REQ-09-08, REQ-09-09 | pending-human-verification | With Full Keyboard Access enabled if needed, open the menu and traverse tabs, refresh cadence, `Retry now`, `Settings...`, `Quit Kubebar`, watchlist details, warning events, node summaries, pod summaries, and Settings fields. | Native keyboard traversal reaches all required controls and disabled states remain visible and understandable. | Native SwiftUI controls and shortcuts are present in source. Human keyboard traversal evidence is still required. | Keyboard traversal depends on macOS focus settings and cannot be reliably proven by current automation. |
| Long names use middle truncation with full help/accessibility | REQ-09-10, REQ-09-03, REQ-09-04, REQ-09-05, REQ-09-06 | pending-human-verification | Use long context, namespace, workload, pod, node, and event object names; inspect Overview and resource tabs; check hover help or accessibility labels. | Long values stay one line with middle truncation. Full values remain available through help/accessibility labels without exposing command transcripts or JSON. | Plan 01 and existing view patterns preserve `.truncationMode(.middle)`, help text, and accessibility labels for display names. Visible and accessibility evidence is still required. | Use fixture names or redacted observations; do not commit sensitive real cluster identifiers. |

## Human Evidence Needed

| Area | Needed Evidence | Safe Recording Rule |
| --- | --- | --- |
| Opened menu states | Screenshot path or concise human observation for OK, Watch, Bad, and Stale states. | Use app-owned fixture names or redact real context/object names. |
| Tab switching and reopen reset | Observation that tab content changes without refresh and reopen returns to Overview. | Record only behavior, not command output. |
| Settings | Observation that `Settings...` opens a separate Settings dialog/window. | Do not include local filesystem paths unless they are the built app path. |
| Quit | Observation that app exits and saved config fields remain unchanged after relaunch. | Summarize preserved field names only. |
| Keyboard and long names | Observation that focus traversal and truncation behave as expected. | Avoid screenshots or text containing sensitive cluster identifiers. |

## Visible App Smoke Evidence

| Check | Result | Evidence | Limitation |
| --- | --- | --- | --- |
| `./scripts/compile-and-run.sh` | pass | Built and launched `DerivedData/Build/Products/Debug/Kubebar.app` with PID `50212`. | This confirms launch only. It does not inspect the opened menu, Settings window, keyboard traversal, or Quit behavior. |

## Requirement Coverage

| Requirement | UAT Coverage |
| --- | --- |
| REQ-09-01 | OK/Watch/Bad/Stale open-menu rows, tab switching row, reopen reset row, keyboard row. |
| REQ-09-02 | Tab switching without refresh row and reopen reset row. |
| REQ-09-03 | Overview state rows, empty watchlist row, long-name row. |
| REQ-09-04 | Stale row, tab switching row, long-name row. |
| REQ-09-05 | Bad row, stale row, tab switching row, long-name row. |
| REQ-09-06 | Watch row, stale row, tab switching row, long-name row. |
| REQ-09-07 | Empty watchlist Settings path, Settings dialog/window row, keyboard row. |
| REQ-09-08 | Quit row and keyboard row. |
| REQ-09-09 | Settings, Quit, and keyboard rows. |
| REQ-09-10 | Status rows, empty watchlist row, and long-name row. |
