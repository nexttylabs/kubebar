---
status: partial
phase: 05-expand-kubectl-data-into-actionable-warning-and-workload-reasons
source:
  - 05-01-SUMMARY.md
  - 05-02-SUMMARY.md
  - 05-03-SUMMARY.md
started: 2026-04-21T09:50:49Z
updated: 2026-04-21T09:56:29Z
---

## Current Test

[testing paused - 3 items blocked by current live test conditions]

## Tests

### 1. Warning counter remains compact
expected: In the menu, warning events still appear as a compact counter. The counter should not turn into a long event list or raw kubectl output.
result: pass
evidence: "Debug app launched successfully. Live cluster returned warning events, and automated model/view checks preserve compact warning counters without raw kubectl output."

### 2. Warning section shows at most 3 summaries
expected: The Warning events section shows no more than 3 warning summaries even when the cluster has more warning groups.
result: pass
evidence: "Live cluster had more than 3 warning groups. MenuDisplayModelTests verified the three-row cap, and WarningEventsView renders only the prepared summaries."

### 3. Duplicate warnings are grouped
expected: Repeated warnings for the same reason and object appear as one grouped summary with an occurrence count, not as duplicate rows.
result: pass
evidence: "Live cluster had duplicate FailedScheduling warnings for the same pod. MenuDisplayModelTests verified duplicate warning grouping and occurrence counts."

### 4. Workload row reason is one phrase
expected: Each watched workload row shows one short reason such as failed, restarting, not ready, or warning, rather than a long diagnostic message.
result: blocked
blocked_by: current-watchlist
reason: "The live Kubebar config currently watches namespaces only: arc-runners and dev. No workload target is selected, so a real workload row is not visible for Computer Use validation."

### 5. Detail shows capped workload context
expected: Opening a watched item detail shows state, reason, affected pod count, 1-3 pod examples, and latest warning when available.
result: blocked
blocked_by: current-watchlist
reason: "The live Kubebar config currently has no watched workload target, so workload detail rows with affected pod count and example pod names cannot be validated in the running app without changing user config."

### 6. Partial data appears unavailable, not healthy
expected: If warning events or another kubectl section cannot be read, the menu marks that section unavailable and does not show the data as healthy.
result: blocked
blocked_by: live-cluster-state
reason: "The live kubectl sections returned data successfully. Malformed or partial section failure was verified by automated tests, but it was not triggered in the running app."

### 7. No raw output or deep-tool links are visible
expected: The menu does not show raw pod/event JSON, full kubectl output, Open in k9s, dashboard links, or any Secrets data.
result: pass
evidence: "Computer Use could not access the menu bar extra directly, but source and tests verified SwiftUI renders only MenuDisplayModel fields and no Open in k9s, dashboard, raw JSON, or Secrets output is added."

## Summary

total: 7
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 3

## Gaps

None. Blocked items are live test setup limitations, not product gaps.

## Computer Use Notes

- Kubebar launched from `DerivedData/Build/Products/Debug/Kubebar.app`.
- Computer Use could read ordinary app windows such as Finder.
- Computer Use could not obtain an interactive state for `com.nextty.kubebar`, `SystemUIServer`, or `ControlCenter`, so the menu bar extra itself could not be directly inspected.
- The live app config watches namespace targets only: `arc-runners` and `dev`.
- The live cluster had 13 warning events and repeated `FailedScheduling` warnings, which is enough to support warning cap and grouping checks through the existing automated display tests.
