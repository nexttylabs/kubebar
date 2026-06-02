---
title: Health State Shift Alerts
date: 2026-06-01
status: planned
origin: user brainstorm plus Settings follow-up
---

# Health State Shift Alerts

## Summary

Kubebar should optionally send macOS notifications when the cluster Health
category or watchlist attention genuinely gets worse. The feature is a local
app behavior: it consumes the existing `MenuDisplayModel`, respects
`HealthEvaluator` as the single source of truth, and does not add new
Kubernetes reads or resource-pressure alert rules.

The smallest useful version is a Settings toggle for `Health State Shift
Alerts`, a macOS `UserNotifications` delivery boundary, and a small alert
decision policy that only emits notifications for fresh, comparable worsening
states.

## Goals

- Settings exposes a notification setting for `Health State Shift Alerts`.
- The setting is persisted with Kubebar's app config and defaults off.
- Turning the setting on requests macOS notification authorization.
- If authorization is denied or unavailable, the setting stays off and Settings
  shows a short recoverable message.
- Notifications fire only after a previous comparable fresh Health category has
  been seen.
- Notifications fire for `OK -> Watch`, `OK -> Bad`, and `Watch -> Bad`.
- Notifications fire when a watched item newly becomes Bad, including the
  existing crash-loop/restarting watchlist signal.
- Repeated refreshes of the same state and same watchlist reason do not spam
  notifications.
- Turning the setting off stops delivery without changing refresh, stale, or
  Health category behavior.

## Non-Goals

- No resource-pressure alerting.
- No historical trend storage or dashboard behavior.
- No Prometheus, Grafana, Alertmanager, or external monitoring integration.
- No new Kubernetes reads beyond the existing refresh flow.
- No changes to `HealthEvaluator` severity rules.
- No notification for stale age-out in this slice.
- No deep macOS notification troubleshooting UI.

## Requirements

- R1. Settings must show a clear `Health State Shift Alerts` toggle for setup
  and existing Settings editing.
- R2. The toggle must be persisted in `AppConfig` with backward-compatible
  decoding for existing config files.
- R3. The default value must be off so Kubebar does not request notification
  permission unexpectedly.
- R4. Enabling the setting must request notification authorization through an
  injectable boundary.
- R5. Denied or failed authorization must leave the setting off and show a
  short recoverable Settings message.
- R6. Delivery must use macOS `UserNotifications` behind an injectable app
  boundary.
- R7. Alert decisions must consume `MenuDisplayModel`; they must not infer
  Health category independently from raw Kubernetes data.
- R8. `Stale` must not be treated as a directionally worse fresh cluster state
  for these alerts.
- R9. First refresh after launch must establish a baseline without notifying.
- R10. Top-level notifications must fire only for `OK -> Watch`, `OK -> Bad`,
  and `Watch -> Bad`.
- R11. Watchlist notifications must compare the full watched-item alert
  fingerprint, including rows hidden by the first-screen cap, and fire when a
  watched item newly becomes worse, especially newly Bad/restarting items.
- R12. Unchanged alert fingerprints must not notify repeatedly across refreshes.
  Raw reason text changes alone are not directional deterioration; structured
  affected-pod count increases may notify.
- R13. If alerts are disabled, Kubebar may continue updating the comparison
  baseline so enabling alerts later starts from the current known state.
- R14. Notification text must use safe display strings such as context, Health
  label, watch item title, and reason; it must not expose command transcripts,
  raw JSON, Secrets, or credentials.
- R15. The feature must not affect refresh cadence, Start at Login, selected
  context, watchlist selection, k9s handoff, stale display, or Health category.
- R16. Watchlist alert fingerprints must use stable target identity, including
  workload kind, instead of display title alone.

## Verification Expectations

- Focused unit tests cover alert decisions for first baseline, top-level
  worsening, non-worsening changes, stale exclusion, watchlist newly Bad
  changes, same-title workload kind separation, and unchanged refresh
  deduplication.
- Config tests cover default-off decoding and round-trip persistence.
- Runtime state tests cover Settings save and unsaved-change behavior for the
  notification setting.
- Authorization coordinator tests cover granted and denied enable attempts.
- `./scripts/swift-quality-gate.sh local` passes.
- A visible Settings smoke check can confirm the notification toggle is present
  and reachable.
