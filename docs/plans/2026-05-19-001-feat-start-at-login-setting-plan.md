---
title: feat: Add Start at Login setting
type: feat
status: planned
date: 2026-05-19
origin: .imm/specs/2026-05-19-start-at-login-setting.md
---

# feat: Add Start at Login setting

## Summary

- Summary: Start at Login can be controlled from Settings.

Add a Settings toggle that lets the user choose whether Kubebar opens
automatically after macOS login. This is local app behavior and does not alter
cluster configuration, refresh cadence, Kubernetes reads, or Health category
evaluation.

## Task

- Type: feat
- Scope: start at login setting
- Owner: imm-work
- Verification: automated plus visible smoke

## Origin

The user requested `/prep 添加start at login设置` on 2026-05-19. The request is
stable enough for direct planning: add a macOS Settings control for Start at
Login and keep the scope limited to local app behavior.

## Research

- `CONTEXT.md` now defines `Start at Login setting` as local app behavior that
  must not affect Health category.
- `docs/architecture/runtime-invariants.md` says Settings owns refresh cadence,
  `AppConfigStore` owns saved context and watchlist, and Health category is
  decided only by `HealthEvaluator`.
- `Kubebar/Views/SetupView.swift` renders the current Settings content:
  context picker, watchlist picker, refresh cadence picker, and save footer.
- `Kubebar/Views/SettingsRootView.swift` owns Settings window sizing and passes
  callbacks into `SetupView`.
- `Kubebar/MenuBarViewModel.swift` owns app-level Settings actions and is the
  right place to coordinate an injected login item boundary.
- `KubebarCore/Services/AppConfigStore.swift` persists cluster setup fields.
  The Start at Login state should not be added there because macOS login item
  status is the source of truth.
- `Package.swift` and `project.yml` target macOS 14, so `SMAppService.mainApp`
  is available for the production boundary.
- `docs/solutions/rejected-decisions/pod-resource-history-alerting-2026-05-14.md`
  is the only rejected decision entry found and is unrelated.

## Decisions

- Implement this as one outcome unit: Start at Login can be controlled from
  Settings.
- Use the macOS ServiceManagement login item API behind a small injectable
  boundary.
- Keep the persisted app config focused on Kubernetes context, watchlist, and
  refresh cadence.
- Treat failed login item updates as recoverable Settings feedback, not as
  setup failure or Health category input.
- Keep the toggle native SwiftUI for keyboard and accessibility behavior.

## Assumptions

- `SMAppService.mainApp.status` is sufficient to reflect whether Kubebar is
  registered to start at login.
- A fake login item boundary can cover enable, disable, status refresh, and
  failure rollback without touching the user's actual login items.
- The existing Settings window maximum height can still fit one additional
  compact toggle row; if not, the current scroll view already preserves access
  to all controls.

## Scope Boundaries

- In scope: Settings toggle, injected login item controller, status refresh
  when Settings opens, recoverable failure feedback, focused tests, and runtime
  invariant documentation.
- Out of scope: login helper targets, LaunchAgent files, daemon behavior,
  cluster config persistence changes, Kubernetes reads, Health category logic,
  and deep macOS troubleshooting UI.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Start at Login can be controlled from Settings.
- Verification: /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Depends on: None
- Test scenarios: Settings state reflects current login item status; enabling registers the login item through a fake boundary; disabling unregisters the login item through a fake boundary; failed updates roll the toggle back and show recoverable feedback; existing cluster setup completion remains independent from Start at Login; visible Settings smoke check confirms the toggle is reachable

**Goal:** Add a native Settings toggle for Start at Login without changing
Kubernetes setup, refresh, or health semantics.

**Verification type:** hitl

**Execution note:** test-first

**Requirements:** R1-R10

**Dependencies:** None

**Files:**
- Modify: `Kubebar/Views/SetupView.swift`
- Modify: `Kubebar/Views/SettingsRootView.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `Kubebar/KubebarApp.swift`
- Modify: `KubebarCore/Models/SetupFlowState.swift`
- Modify: `KubebarCore/Models/MenuRuntimeState.swift`
- Modify: `KubebarTests/Models/SetupFlowStateTests.swift`
- Modify: `KubebarTests/Models/MenuRuntimeStateTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Create: `Kubebar/Services/LoginItemController.swift`
- Reference: `.imm/specs/2026-05-19-start-at-login-setting.md`
- Reference: `CONTEXT.md`

**Approach:**
- Add focused tests first around the Settings state needed for status display,
  successful enable/disable, and failed update rollback using an injected fake.
- Introduce a small app-target login item controller that wraps
  `SMAppService.mainApp` for production.
- Let `MenuBarViewModel` refresh the Start at Login state when Settings opens
  and handle toggle changes through the injected boundary.
- Pass the toggle state and change callback through `SettingsRootView` into
  `SetupView`.
- Render a compact native Toggle near refresh cadence, with short failure
  feedback when the system update cannot be applied.
- Update runtime invariants to state that Start at Login is a local Settings
  behavior and does not affect cluster health or saved Kubernetes config.

**Verification:**
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local`
- `/usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer KUBEBAR_QA_STATE=setup ./scripts/compile-and-run.sh`
- Open Settings and confirm `Start at Login` is visible, keyboard reachable,
  and does not block finishing setup or saving existing cluster settings.

**failure_behavior:** If macOS rejects the registration update, keep the actual
system status as the displayed toggle state and show a short recoverable
message in Settings.

**security_considerations:** No Kubernetes data, Secrets, credentials, command
transcripts, or network requests are added. The only new external effect is
registering or unregistering the current app with macOS login items.

## Validation Notes

- Use the system Immune-Brain CLI: `imm-plan docs/plans/2026-05-19-001-feat-start-at-login-setting-plan.md --json`.
