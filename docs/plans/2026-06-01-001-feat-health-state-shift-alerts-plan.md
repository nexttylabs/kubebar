---
title: "feat: Add Health State Shift Alerts"
type: feat
status: planned
date: 2026-06-01
origin: .imm/specs/2026-06-01-health-state-shift-alerts.md
---

# feat: Add Health State Shift Alerts

## Summary

- Summary: Settings can enable macOS notifications for true Health category or
  watchlist deterioration.

Add an optional Settings-controlled notification feature for directionally
worse cluster Health category changes and newly worse watchlist items. The
feature consumes `MenuDisplayModel`, keeps `HealthEvaluator` authoritative, and
does not add resource-pressure alerting or external monitoring behavior.

## Task

- Type: feat
- Scope: Health State Shift Alerts setting and delivery
- Owner: imm-work
- Verification: automated plus visible Settings smoke

## Origin

The user requested `集群顶级健康状态恶化主动提醒 (Health State Shift Alerts)` and
then clarified that Settings must include a notification setting. The upstream
brainstorm established that alerts should only fire on true directionally worse
states and must not become resource-pressure or historical alerting.

## Brainstorm Manifest

- `BR-REQ-001`: Integrate macOS `UserNotifications`.
- `BR-REQ-002`: Notify only on true directionally worse Health category changes.
- `BR-REQ-003`: Watchlist newly Bad/CrashLoop-style issues can trigger alerts.
- `BR-REQ-004`: Repeated unchanged issues must not spam notifications.
- `BR-REQ-005`: Settings must include a notification setting.
- `BR-DEC-001`: Notification logic consumes `MenuDisplayModel` and does not
  independently decide Health category.
- `BR-DEC-002`: Notification setting defaults off and enabling it requests
  macOS authorization.
- `BR-DEC-003`: `Stale` is excluded from fresh directionally worse alerts in
  this slice.
- `BR-OUT-001`: No resource-pressure alerting.
- `BR-OUT-002`: No historical trends, external monitoring, or deep
  troubleshooting.

## Brainstorm Trace

| ID | Status | Mapping |
| --- | --- | --- |
| `BR-REQ-001` | covered_by_step | U1 adds a `UserNotifications` delivery boundary. |
| `BR-REQ-002` | covered_by_step | U1 adds alert decision tests and implementation for worsening Health category shifts. |
| `BR-REQ-003` | covered_by_step | U1 covers newly worse watchlist item fingerprints. |
| `BR-REQ-004` | covered_by_step | U1 covers unchanged fingerprint deduplication. |
| `BR-REQ-005` | covered_by_step | U1 adds the Settings toggle and persisted config. |
| `BR-DEC-001` | captured_as_decision | Alert decisions compare `MenuDisplayModel` fields only. |
| `BR-DEC-002` | captured_as_decision | Config default is off; enabling requests authorization. |
| `BR-DEC-003` | captured_as_decision | `Stale` does not trigger Health State Shift notifications. |
| `BR-OUT-001` | out_of_scope | Resource pressure remains display-only per runtime invariants. |
| `BR-OUT-002` | out_of_scope | This slice remains local app notification behavior only. |

## Research

- `CONTEXT.md` now defines `Health State Shift Alerts` as optional local app
  notifications that consume `MenuDisplayModel` and must not add health rules.
- `docs/architecture/runtime-invariants.md` keeps `HealthEvaluator` as the
  single source of truth, stale data visibly stale, resource visualization
  display-only, and Settings as the owner of refresh cadence.
- `docs/solutions/rejected-decisions/pod-resource-history-alerting-2026-05-14.md`
  rejects resource-pressure/history alert expansion; this plan avoids that by
  only alerting on existing Health category/watchlist deterioration.
- `docs/solutions/app-settings/start-at-login-boundary-2026-05-19.md` provides
  the reusable shape for macOS app settings: local system API behind an
  injectable boundary, plain state in Settings, and no Kubernetes semantics.
- `Kubebar/MenuBarViewModel.swift` already centralizes refresh result
  application and Settings actions, making it the right place to record alert
  baselines and trigger delivery after successful result application.
- `Kubebar/Views/SetupView.swift`, `SettingsRootView.swift`, and
  `KubebarCore/Models/MenuRuntimeState.swift` already carry Settings controls
  and persisted setup state.
- `KubebarCore/Services/AppConfigStore.swift` persists app-owned local config
  and needs a backward-compatible notification setting default.

## Decisions

- Implement as one outcome unit: Health State Shift Alerts can be enabled from
  Settings and notify only on true deterioration.
- Persist the setting in `AppConfig` as local app config, defaulting off.
- Request macOS notification authorization when the user turns the toggle on;
  denial keeps the setting off with a recoverable message.
- Compare only fresh `OK`, `Watch`, and `Bad` states; exclude `Stale` from
  alert-triggering comparisons.
- Keep a comparison baseline even when delivery is disabled so enabling alerts
  later starts from the current known state.
- Prefer existing source files already included by Xcode for new helper types
  to avoid project-file churn unless the implementation becomes too crowded.

## Assumptions

- A visible watched item becoming Bad/restarting is sufficient to represent the
  requested new CrashLoop-style watchlist alert in this slice.
- If multiple deteriorations appear in one refresh, one concise notification is
  enough; the menu remains the detailed surface.
- macOS notification delivery can fail silently without changing Health
  category or Settings saved state.
- The existing Settings scroll view can keep one additional compact toggle row
  reachable within the current window limits.

## Devil's Advocate Audit

- Rollback resilience: the smallest coherent rollback is the Settings/config
  fields, alert decision helper, notification boundary, tests, CONTEXT entry,
  and runtime-invariants note. Existing config decoding must remain
  backward-compatible so partial rollout does not strand old users.
- Verification vanity: unit tests must assert actual alert decisions and config
  defaults, not just that files compile. The quality gate must still run Xcode
  and SwiftPM paths so app-target `UserNotifications` wiring is compiled.
- Spec dilution detection: the user-added Settings requirement is explicitly
  mapped as `BR-REQ-005`; stale alerts and resource-pressure alerts are
  deliberately excluded and recorded, not silently dropped.

## Planning Quality Gate

- Contract surface: `AppConfig`, `MenuRuntimeState`, `SetupFlowState`,
  `SetupView`, `SettingsRootView`, `MenuBarViewModel`, the app notification
  boundary, alert decision helper, tests, `CONTEXT.md`, and runtime invariants.
- Compatibility: existing config files decode with alerts off; users must opt
  in before macOS permission is requested.
- Interruption recovery: if implementation stops midway, `imm-work` resumes U1
  from the current changed files and re-runs the same quality gate.
- Rollback path: revert U1's implementation/test/docs files together; no data
  migration is needed because the new config key is optional.
- Verification strength: use focused unit tests plus
  `./scripts/swift-quality-gate.sh local`; visible Settings smoke is useful but
  not the only acceptance signal.
- Brainstorm traceability: every `BR-*` item above is mapped.

## Scope Boundaries

- In scope: Settings toggle, persisted default-off config, notification
  authorization, `UserNotifications` delivery boundary, alert decision logic,
  deduplication, focused tests, and runtime invariant documentation.
- Out of scope: resource-pressure thresholds, historical alert storage,
  external monitoring integrations, raw Kubernetes event subscriptions, stale
  age-out notifications, and deep notification troubleshooting UI.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Settings-controlled Health State Shift Alerts notify only on true deterioration.
- Verification: /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Depends on: None
- Test scenarios: existing configs decode with alerts off; enabled alert setting round trips through config; Settings runtime state preserves and saves the alert setting; enabling denied notification authorization keeps the toggle off with feedback; first fresh display establishes an alert baseline without notification; OK to Watch or Bad and Watch to Bad produce one alert; Stale does not produce an alert; repeated unchanged Bad state does not re-notify; a newly Bad watchlist item produces an alert

**Goal:** Add Settings-controlled macOS notifications for true Health category
or watchlist deterioration without changing Kubernetes health semantics.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1-R15

**Dependencies:** None

**Discovery cache:**
- `Kubebar/MenuBarViewModel.swift` (refresh result application and Settings actions)
- `Kubebar/Views/SetupView.swift` (Settings controls)
- `Kubebar/Views/SettingsRootView.swift` (Settings callback plumbing)
- `Kubebar/KubebarApp.swift` (Settings callback wiring)
- `Kubebar/Services/LoginItemController.swift` (existing app-target macOS settings boundary file)
- `KubebarCore/Services/AppConfigStore.swift` (persisted config)
- `KubebarCore/Models/MenuRuntimeState.swift` (Settings save state)
- `KubebarCore/Services/HealthEvaluator.swift` (source of display model states)
- `KubebarCore/Models/MenuDisplayModel.swift` (alert input surface)
- `docs/architecture/runtime-invariants.md` (product/runtime rules)

**Files:**
- Modify: `CONTEXT.md`
- Modify: `.imm/specs/2026-06-01-health-state-shift-alerts.md`
- Modify: `docs/plans/2026-06-01-001-feat-health-state-shift-alerts-plan.md`
- Modify: `KubebarCore/Services/AppConfigStore.swift`
- Modify: `KubebarCore/Models/StartAtLoginState.swift`
- Modify: `KubebarCore/Services/StartAtLoginSettingsCoordinator.swift`
- Modify: `KubebarCore/Models/SetupFlowState.swift`
- Modify: `KubebarCore/Models/MenuRuntimeState.swift`
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Modify: `Kubebar/Services/LoginItemController.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `Kubebar/Views/SetupView.swift`
- Modify: `Kubebar/Views/SettingsRootView.swift`
- Modify: `Kubebar/KubebarApp.swift`
- Modify: `KubebarTests/Services/AppConfigStoreTests.swift`
- Modify: `KubebarTests/Services/StartAtLoginSettingsCoordinatorTests.swift`
- Modify: `KubebarTests/Models/MenuRuntimeStateTests.swift`
- Modify: `KubebarTests/Models/MenuDisplayModelTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`

**Approach:**
- Add tests first for config persistence, Settings state, authorization
  coordinator behavior, and alert decision behavior.
- Add a default-off alert setting to `AppConfig` with compatible decoding.
- Extend Settings state and UI with a compact native toggle near other local
  app settings.
- Add an injectable notification authorization/delivery boundary and production
  `UserNotifications` implementation.
- Add a small alert decision helper that compares current and previous
  `MenuDisplayModel` alert fingerprints.
- Call the helper after refresh result application; deliver only when the saved
  setting is enabled.
- Update runtime invariants to describe the notification setting and its
  non-effect on Health category.

**Verification:**
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- Optional visible smoke: `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer KUBEBAR_QA_STATE=setup ./scripts/compile-and-run.sh`, then open Settings and confirm the Health State Shift Alerts toggle is reachable.

**failure_behavior:** Authorization denial keeps the setting off with a short
Settings message. Notification delivery failure does not alter display state,
refresh cadence, or saved Kubernetes configuration.

**security_considerations:** Notification text uses only safe display-model
strings. No Kubernetes Secrets, command transcripts, raw JSON, credentials, or
new network/API reads are introduced.

## Validation Notes

- Use the system Immune-Brain CLI:
  `/Users/derek/.codex/plugins/cache/agent-skills/immune-brain/0.5.7/bin/imm-plan docs/plans/2026-06-01-001-feat-health-state-shift-alerts-plan.md --json`.
