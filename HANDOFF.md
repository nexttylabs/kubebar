# Kubebar Handoff

## Current State

- Plan: `docs/plans/2026-06-01-001-feat-health-state-shift-alerts-plan.md`
- Status: complete
- Completed steps: U1 `Settings-controlled Health State Shift Alerts notify only on true deterioration.`
- Latest review: pass
- Review follow-up: fixed delayed notification authorization results so they
  cannot override a later toggle or successful save.
- Review follow-up: fixed P2 code-review findings for save-failure config
  pollution, reason-text-only alert re-notification, and hidden watchlist item
  alert coverage.
- Review follow-up: fixed same-name workload kind identity collisions so
  Deployment and StatefulSet `namespace/name` rows compare as distinct alert
  targets.

## Verification

- `swift test`
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`

## Notes

- Settings now includes a `Health State Shift Alerts` toggle.
- The alert setting is persisted in `AppConfig`, defaults off for new and
  existing configs, and requests macOS notification authorization when enabled.
- Denied notification authorization leaves the toggle off and shows recoverable
  Settings feedback.
- Alert decisions compare fresh `MenuDisplayModel` states only: first refresh
  establishes a baseline, `Stale` is excluded, repeated unchanged issues are
  deduplicated, and newly worse watchlist items can notify even when the item is
  hidden by the first-screen cap.
- Delivery uses an injectable `UserNotifications` boundary in the app target.
- Settings authorization requests now use a latest-request gate; closing over an
  old authorization result is ignored after a later toggle, settings refresh, or
  successful save.
- Same-`Bad` watchlist rows no longer notify merely because reason text changes;
  structured affected-pod count increases can still notify.
- Watchlist alert identity now includes workload kind while preserving compact
  display titles such as `team/api`.
- Settings save failure no longer mutates the in-memory committed config before
  persistence succeeds.
- No resource-pressure alerting, historical monitoring, new Kubernetes reads,
  or `HealthEvaluator` rule changes were added.
- No known blockers.

## Compaction Handoff

- Active plan: `docs/plans/2026-06-01-001-feat-health-state-shift-alerts-plan.md`
- Active step: none; U1 is closed.
- Priority files:
  - `Kubebar/MenuBarViewModel.swift`
  - `KubebarCore/Models/MenuDisplayModel.swift`
  - `KubebarCore/Services/HealthEvaluator.swift`
  - `KubebarTests/Models/MenuDisplayModelTests.swift`
  - `KubebarCore/Models/StartAtLoginState.swift`
  - `Kubebar/Views/SetupView.swift`
- Uncommitted work summary: Health State Shift Alerts implementation, tests,
  docs/spec/plan, review follow-up fix, workflow state, and handoff update are
  uncommitted.
- Session decisions: notification setting defaults off; enabling requests
  authorization; `Stale` does not trigger alerts; alert logic consumes
  `MenuDisplayModel`; full watchlist alert fingerprints are allowed while UI
  rows remain capped.
- Next boundary skill: optional `imm-compounder` for reusable learning capture.
