---
title: Pod Micro-Logs Drawer
date: 2026-06-20
status: planned
origin: user requested one-step full realtime Pod crash log viewer
---

# Pod Micro-Logs Drawer

## Summary

Kubebar should add a temporary, bounded live log drawer for `Bad` Pod rows.
When a watched Pod row is `Bad`, the Pods tab shows a small log button on that
row. Clicking it opens a native SwiftUI Sheet that runs
`kubectl logs --tail=100 -f -n <namespace> <pod-name>` with Kubebar's
app-owned context and effective kubeconfig, displays the stream as read-only
text, and offers copy plus simple local keyword search.

This is a micro troubleshooting surface. It helps the user decide what to do
next before opening deeper tools, but it must not become stored log history,
alerting, aggregation, or a Health category input.

## Goals

- Show a log affordance only for Pod rows whose display state is `Bad`.
- Open logs in a native SwiftUI Sheet, not inline inside the menu list.
- Start with the last 100 lines and keep following live output.
- Cancel the underlying `kubectl logs -f` process when the Sheet closes, the
  user changes context, the selected Pod changes, or the view model deinitializes.
- Keep an in-memory bounded buffer so long-running streams cannot grow without
  limit.
- Show loading, connected, ended, empty, failed, and cancelled states clearly.
- Provide copy-current-log and simple keyword search over the current buffer.
- Use Kubebar's app-owned selected context and effective kubeconfig, never the
  terminal current context.
- Keep logs out of persistence, notifications, Health category computation, and
  automatic refresh data.

## Non-Goals

- No stored historical logs.
- No cross-Pod aggregation.
- No warning or notification generation from log contents.
- No change to `HealthEvaluator` severity rules.
- No Kubernetes Secret reads.
- No mutation of Kubernetes resources or kubeconfig current context.
- No full terminal emulator or k9s replacement.
- No advanced query language, regex mode, or server-side log filtering in the
  first implementation.
- No multi-container picker unless `kubectl logs` returns an error that the
  user can act on; a later slice can add explicit container selection.

## Requirements

- R1. `PodItemDisplay` must carry enough safe identity for a Pod log request:
  namespace, Pod name, and whether a log button should be shown.
- R2. Only `Bad` Pod rows expose the log button.
- R3. The log button must be accessible and visually compact, using a familiar
  log/document SF Symbol and a short help/accessibility label.
- R4. Opening the button presents a SwiftUI Sheet for exactly one Pod target.
- R5. The Sheet must start a bounded live stream equivalent to
  `kubectl logs --tail=100 -f -n <namespace> <pod-name>` plus the app-owned
  `--context <selectedContext>`.
- R6. The stream must use the same effective kubeconfig behavior as other
  Kubebar kubectl reads, including explicit App Settings kubeconfig paths.
- R7. Closing the Sheet or replacing the target must cancel the subprocess and
  release file handles.
- R8. The log buffer must remain memory-bounded; the initial target is to keep
  no more than 1000 visible lines.
- R9. The UI must show loading, live/connected, ended, empty, failure, and
  cancellation states without exposing command transcripts.
- R10. Copy logs copies only the current in-memory buffer.
- R11. Search is local to the current buffer and highlights or navigates simple
  keyword matches without changing the Kubernetes read.
- R12. Logs must not be written to app config, docs, telemetry, alerts, or the
  refresh snapshot.
- R13. Health categories remain `OK`, `Watch`, `Bad`, or `Stale`, still decided
  only by `HealthEvaluator`.
- R14. Stale or unavailable Pod data must not expose fresh-looking log buttons.

## Verification Expectations

- Model tests prove `Bad` Pod rows expose a log target and non-`Bad` rows do not.
- Service tests prove log requests include `logs`, `--tail=100`, `-f`, namespace,
  Pod name, app-owned `--context`, and effective kubeconfig overrides.
- Streaming service tests prove stdout/stderr chunks append, failures surface
  safe messages, cancellation terminates the process, and the buffer caps lines.
- View model tests prove opening, replacing, and closing a log target manages
  stream state and cancellation.
- UI/build verification proves the Pods tab and Sheet compile with accessible
  copy/search controls.
- Runtime invariants are updated to document that user-opened Pod logs are a
  bounded troubleshooting surface and not Health input.
- Full quality gate remains the final verification.
