---
title: "feat: configure explicit kubeconfig paths in settings"
type: feat
status: planned
date: 2026-06-04
origin: .imm/specs/2026-06-04-explicit-kubeconfig-path-list.md
---

# feat: configure explicit kubeconfig paths in settings

## Summary

- Summary: Add an App Settings kubeconfig path list that overrides automatic
  `KUBECONFIG` detection and drives every `kubectl` read.

This is the follow-up to the multi-file `KUBECONFIG` inheritance fix. The
previous slice kept automatic detection working; this slice makes kubeconfig
file selection app-owned and visible so GUI-launched Kubebar can reliably list
all configured contexts.

## Current Slice

- Roadmap source: none
- Execution scope: persisted kubeconfig paths, runtime Settings state, kubectl
  environment resolution, App Settings controls, and tests/docs for those
  behaviors
- Deferred phases: richer validation, file-change monitoring, and a kubeconfig
  content editor remain outside this plan
- This is not a full kubeconfig management roadmap.

## Task

- Type: feat
- Scope: App Settings, app config persistence, kubectl command environment, and
  tests/docs
- Owner: imm-work
- Verification: focused Swift tests, UI smoke when practical, and full Swift
  quality gate
- Brainstorm manifest: BR-REQ-1; BR-REQ-2; BR-REQ-3; BR-REQ-4; BR-REQ-5; BR-DEC-1; BR-DEC-2; BR-DEC-3; BR-OUT-1; BR-OUT-2; BR-DEFER-1; BR-Q-1; BR-Q-2

## Origin

The user reported that the contexts list still does not include all contexts.
We identified automatic `KUBECONFIG` inheritance as insufficient for the GUI
app path and brainstormed an explicit App Settings kubeconfig path list. The
user resolved the open questions:

- `BR-Q-1`: empty path list should fall back to automatic detection.
- `BR-Q-2`: adding paths should support a native file picker.

## Brainstorm Manifest

- `BR-REQ-1`: Kubebar must support an App Settings kubeconfig path list.
- `BR-REQ-2`: All kubectl reads must use one app-owned kubeconfig source.
- `BR-REQ-3`: Linux/macOS multi-file merging remains delegated to `kubectl`.
- `BR-REQ-4`: Kubeconfig paths are a global app setting, not context-tab state.
- `BR-REQ-5`: Missing contexts are not selectable, but saved watchlists for
  missing contexts are preserved.
- `BR-DEC-1`: Do not parse or merge kubeconfig YAML in Kubebar.
- `BR-DEC-2`: Explicit configured paths take precedence over environment
  detection.
- `BR-DEC-3`: Persist the path list in `AppConfig`.
- `BR-OUT-1`: No kubeconfig file content editor.
- `BR-OUT-2`: No automatic file watching.
- `BR-DEFER-1`: Rich path existence/readability validation and more granular
  error messages are deferred.
- `BR-Q-1`: Empty path list fallback behavior.
- `BR-Q-2`: Path-add UI mechanism.

## Brainstorm Trace

| Item | Status | Target | Reason |
| --- | --- | --- | --- |
| BR-REQ-1 | covered_by_step | U3 | U1 persists state, U2 wires behavior, and U3 delivers the App Settings path list. |
| BR-REQ-2 | covered_by_step | U2 | U2 makes catalog, target discovery, and refresh use the same effective environment. |
| BR-REQ-3 | captured_as_decision | Decisions | Kubebar joins paths for `KUBECONFIG` and lets `kubectl` merge files. |
| BR-REQ-4 | covered_by_step | U3 | U1 models paths as global config, and U3 places controls in App Settings. |
| BR-REQ-5 | covered_by_step | U3 | U1 keeps watchlists keyed by context, and U3 reloads visible contexts without deleting saved watchlists. |
| BR-DEC-1 | captured_as_decision | Decisions | YAML parsing and merging stay out of scope. |
| BR-DEC-2 | covered_by_step | U2 | U2 verifies explicit paths override inherited or shell `KUBECONFIG`. |
| BR-DEC-3 | covered_by_step | U1 | U1 adds ordered path persistence to `AppConfig`. |
| BR-OUT-1 | out_of_scope | Scope Boundaries | The UI selects files but does not edit their contents. |
| BR-OUT-2 | out_of_scope | Scope Boundaries | Contexts refresh through existing app actions, not file watchers. |
| BR-DEFER-1 | deferred | Deferred Work | Basic load failures remain safe; rich per-file validation can follow later. |
| BR-Q-1 | resolved_as_assumption | Assumptions | User confirmed empty list falls back to automatic detection. |
| BR-Q-2 | covered_by_step | U3 | User confirmed native file picker support. |

## Research

- `CONTEXT.md` defines App Settings, Context Settings tabs, per-context
  watchlists, Quick Context Selector, and the `KUBECONFIG environment`.
- `docs/architecture/runtime-invariants.md` requires app-owned selected context,
  forbids terminal current-context mutation, and requires missing contexts to
  be omitted from selectable context entries while saved watchlists remain.
- `.imm/specs/2026-06-04-kubeconfig-multi-file-support.md` and
  `docs/plans/2026-06-04-001-fix-kubeconfig-multi-file-support-plan.md`
  cover the prior automatic environment slice; this plan is a new slice because
  that slice is closed and its deferred App Settings question is now promoted.
- `KubebarCore/Services/AppConfigStore.swift` persists selected context,
  watchlists, refresh cadence, and alert settings with compatible decoding.
- `KubebarCore/Models/SetupFlowState.swift` and
  `KubebarCore/Models/MenuRuntimeState.swift` own Settings state and completed
  config creation.
- `Kubebar/Views/SetupView.swift` renders App Settings and context tabs.
- `Kubebar/MenuBarViewModel.swift` wires config loading, context discovery,
  watch target loading, and setup completion.
- `KubebarCore/Services/CommandRunner.swift` owns `CommandRequest`
  environment overrides and the automatic `KubectlEnvironment` fallback added
  by the prior slice.
- `KubebarCore/Services/ContextCatalog.swift`,
  `KubebarCore/Services/WatchTargetCatalog.swift`, and
  `KubebarCore/Services/KubectlClusterReader.swift` own kubectl-backed reads.
- `docs/solutions/architecture/per-context-watchlists-active-context-2026-06-03.md`
  is the reusable pattern for preserving watchlists while only one context is
  active.
- Rejected-decision scan found only pod resource history alerting, unrelated to
  kubeconfig path selection.
- Planner subagent dispatch was not used: activation returned no candidates
  because the runtime reported unavailable subagent environment.

## Decisions

- Store kubeconfig paths as an ordered `[String]` in `AppConfig`.
- Treat an empty saved path list as automatic detection.
- Treat a non-empty saved path list as the full app-owned kubeconfig source,
  overriding inherited and shell-detected `KUBECONFIG`.
- Join explicit paths with `:` for Linux/macOS and pass the joined string to
  `kubectl` as `KUBECONFIG`.
- Keep kubeconfig path controls in the fixed App Settings tab.
- Use a native file picker entry point for adding paths.
- Preserve saved per-context watchlists even when context discovery no longer
  returns a context after path changes.
- Keep failure copy safe and avoid showing kubeconfig contents or command
  transcripts.

## Assumptions

- Empty explicit path list falls back to automatic detection, as confirmed by
  the user.
- Add path uses a native file picker, as confirmed by the user.
- macOS/Linux `:` path-list semantics are sufficient for Kubebar.
- Path strings may be stored in local app config because they are local file
  locations; file contents and credentials must not be stored or displayed.
- Existing configs must decode without migration prompts.

## Planning Quality Gate Notes

- Contract surface: `AppConfig`, `SetupFlowState`, `MenuRuntimeState`,
  `SetupView`, `SettingsRootView`, `MenuBarViewModel`, `KubectlEnvironment`,
  `ContextCatalog`, `WatchTargetCatalog`, `KubectlClusterReader`, runtime docs,
  and service/model tests.
- Compatibility: older `config.json` files must decode with an empty
  `kubeconfigPaths` list and keep the current automatic detection behavior.
- Interruption recovery: if execution stops after U1, config can store paths
  but kubectl behavior remains unchanged; U2 owns the behavior switch. If it
  stops after U2, behavior can be tested through injected config but UI may not
  expose editing until U3.
- Rollback path: revert the files touched by the failed step plus any related
  tests/docs for that step. No external kubeconfig file is mutated by this
  plan.
- Verification strength: use Codable/unit tests for persistence, environment
  tests for `KUBECONFIG`, service tests for kubectl request propagation, and
  UI/accessibility smoke for file-picker controls.
- Brainstorm traceability: every `BR-*` item is mapped above.

## Devil's Advocate Audit

- Rollback resilience: The work is split so persistence, kubectl behavior, and
  UI exposure can each be reverted coherently. No step mutates user kubeconfig
  files or Kubernetes resources.
- Verification vanity: Tests must not only assert that a text label exists.
  U2 must fail if explicit paths are omitted or automatic detection wins when
  explicit paths exist. U3 must prove the Settings state changes path order and
  completion output, with UI smoke only supplementing those automated checks.
- Spec dilution detection: The plan covers both user-confirmed questions:
  empty-list fallback and native file picker. It defers only richer validation
  and file watching, both explicitly outside the brainstormed must-have slice.

## Scope Boundaries

- In scope: persisted path list, explicit-vs-automatic environment resolution,
  all kubectl-backed read paths, App Settings controls, context reload behavior,
  and tests/docs.
- Out of scope: kubeconfig YAML parsing, kubeconfig content editing, automatic
  file watching, current-context mutation, HealthEvaluator rules, Kubernetes
  Secrets reads, and raw command transcript display.

## Deferred Work

- Rich validation for missing, duplicate, unreadable, or invalid kubeconfig
  files with per-file feedback.
- Automatic context refresh when a configured kubeconfig file changes on disk.
- Import/export or reset helpers for teams with shared kubeconfig bundles.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Ordered explicit kubeconfig paths persist through Settings state.
- Verification: swift test --filter AppConfigTests && swift test --filter AppConfigStoreTests && swift test --filter SetupFlowStateTests && swift test --filter MenuRuntimeStateTests && rtk git diff --check
- Depends on: None
- Test scenarios: older configs decode with empty kubeconfig paths; explicit paths round trip in config; selecting context preserves kubeconfig paths; preparing Settings exposes saved paths; completed config preserves path order and per-context watchlists

**Goal:** Make kubeconfig paths durable global app settings without changing
kubectl behavior yet.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1, R2, R6, R9

**Dependencies:** None

**Discovery cache:**
- `KubebarCore/Services/AppConfigStore.swift` (persisted config shape)
- `KubebarCore/Models/SetupFlowState.swift` (Settings editing state)
- `KubebarCore/Models/MenuRuntimeState.swift` (completed config and unsaved-change detection)
- `KubebarTests/Models/AppConfigTests.swift` (global config behavior)
- `KubebarTests/Services/AppConfigStoreTests.swift` (Codable compatibility)
- `KubebarTests/Models/SetupFlowStateTests.swift` (Settings state behavior)
- `KubebarTests/Models/MenuRuntimeStateTests.swift` (completed config behavior)

**Files:**
- Modify: `KubebarCore/Services/AppConfigStore.swift`
- Modify: `KubebarCore/Models/SetupFlowState.swift`
- Modify: `KubebarCore/Models/MenuRuntimeState.swift`
- Modify: `KubebarTests/Models/AppConfigTests.swift`
- Modify: `KubebarTests/Services/AppConfigStoreTests.swift`
- Modify: `KubebarTests/Models/SetupFlowStateTests.swift`
- Modify: `KubebarTests/Models/MenuRuntimeStateTests.swift`

**Approach:**
- Add an ordered `kubeconfigPaths` field to `AppConfig` with compatible
  decoding defaulting to `[]`.
- Preserve paths through `selectingContext`.
- Carry paths into `SetupFlowState` and completed config.
- Include path changes in Settings unsaved-change detection.
- Keep empty-list fallback as a represented state, not an error state.

**failure_behavior:** If config decoding or completed config behavior becomes
ambiguous, stop before touching kubectl reads so existing automatic detection
continues to work.

**security_considerations:** Store only local path strings. Do not store
kubeconfig contents, tokens, or merged configs.

### Step 2

- Step ID: U2
- Result: Kubectl-backed reads use explicit AppConfig kubeconfig paths when configured.
- Verification: swift test --filter CommandRunnerTests && swift test --filter ContextCatalogTests && swift test --filter WatchTargetCatalogTests && swift test --filter KubectlClusterReaderTests && swift test --filter RefreshCoordinatorTests && rtk git diff --check
- Depends on: 1
- Test scenarios: empty path list falls back to automatic detection; non-empty path list joins paths with colon; explicit paths override inherited and shell kubeconfig; context discovery uses explicit paths; watch target discovery uses explicit paths; refresh reads use explicit paths with app-owned --context

**Goal:** Route every kubectl-backed read through the same app-owned effective
kubeconfig source.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R2, R3, R4, R5, R10, R11

**Dependencies:** Step 1

**Discovery cache:**
- `KubebarCore/Services/CommandRunner.swift` (effective kubectl environment)
- `KubebarCore/Services/ContextCatalog.swift` (context discovery environment)
- `KubebarCore/Services/WatchTargetCatalog.swift` (watch target environment)
- `KubebarCore/Services/KubectlClusterReader.swift` (refresh command environment)
- `KubebarCore/Services/RefreshCoordinator.swift` (refresh entry from AppConfig)
- `KubebarTests/Services/CommandRunnerTests.swift` (environment selection)
- `KubebarTests/Services/ContextCatalogTests.swift` (context discovery propagation)
- `KubebarTests/Services/WatchTargetCatalogTests.swift` (candidate discovery propagation)
- `KubebarTests/Services/KubectlClusterReaderTests.swift` (refresh propagation)
- `KubebarTests/Services/RefreshCoordinatorTests.swift` (config-driven refresh behavior)

**Files:**
- Modify: `KubebarCore/Services/CommandRunner.swift`
- Modify: `KubebarCore/Services/ContextCatalog.swift`
- Modify: `KubebarCore/Services/WatchTargetCatalog.swift`
- Modify: `KubebarCore/Services/KubectlClusterReader.swift`
- Modify: `KubebarCore/Services/RefreshCoordinator.swift`
- Modify: `KubebarTests/Services/CommandRunnerTests.swift`
- Modify: `KubebarTests/Services/ContextCatalogTests.swift`
- Modify: `KubebarTests/Services/WatchTargetCatalogTests.swift`
- Modify: `KubebarTests/Services/KubectlClusterReaderTests.swift`
- Modify: `KubebarTests/Services/RefreshCoordinatorTests.swift`

**Approach:**
- Extend `KubectlEnvironment` or introduce a narrow value/factory that can
  derive environment overrides from `AppConfig.kubeconfigPaths`.
- Keep automatic fallback only when the configured list is empty.
- Make refresh behavior config-driven so saved path changes affect future
  refreshes instead of being frozen at app launch.
- Keep explicit `--context` on cluster reads.
- Keep failure messages safe and avoid surfacing raw command output beyond the
  existing sanitized paths.

**failure_behavior:** If the environment source cannot be kept consistent
across all services, stop and replan before adding UI controls; a visible
setting without reliable behavior would be misleading.

**security_considerations:** Do not log resolved kubeconfig contents or expose
tokens. Path strings may appear in Settings because the user selected them, but
command transcripts and file contents remain hidden.

### Step 3

- Step ID: U3
- Result: App Settings kubeconfig path management drives context discovery.
- Verification: swift test --filter SetupFlowStateTests && swift test --filter MenuRuntimeStateTests && swift test --filter AppConfigTests && swift test --filter ContextCatalogTests && /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local
- Depends on: 2
- Test scenarios: App Settings has path add/remove/reorder state transitions; file picker callback appends selected paths; saving Settings persists paths; changed path list reloads local context tabs; missing-context watchlists remain saved but hidden from selectable contexts; Settings UI builds in Xcode

**Goal:** Give users a usable App Settings surface for managing explicit
kubeconfig paths.

**Verification type:** automated

**Requirements:** R6, R7, R8, R9, R11

**Dependencies:** Step 2

**Discovery cache:**
- `Kubebar/Views/SetupView.swift` (App Settings UI)
- `Kubebar/Views/SettingsRootView.swift` (settings window integration)
- `Kubebar/MenuBarViewModel.swift` (file picker callback, save, context reload)
- `KubebarCore/Models/SetupFlowState.swift` (path add/remove/reorder state)
- `KubebarCore/Models/MenuRuntimeState.swift` (completed config)
- `KubebarTests/Models/SetupFlowStateTests.swift` (path editing state)
- `KubebarTests/Models/MenuRuntimeStateTests.swift` (save output and context visibility)
- `docs/architecture/runtime-invariants.md` (runtime settings rules)
- `CONTEXT.md` (canonical terms)

**Files:**
- Modify: `Kubebar/Views/SetupView.swift`
- Modify: `Kubebar/Views/SettingsRootView.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `KubebarCore/Models/SetupFlowState.swift`
- Modify: `KubebarCore/Models/MenuRuntimeState.swift`
- Modify: `KubebarTests/Models/SetupFlowStateTests.swift`
- Modify: `KubebarTests/Models/MenuRuntimeStateTests.swift`
- Modify: `KubebarTests/Models/AppConfigTests.swift`
- Modify: `KubebarTests/Services/ContextCatalogTests.swift`
- Modify: `docs/architecture/runtime-invariants.md`
- Modify: `CONTEXT.md`

**Approach:**
- Add App Settings controls for the ordered path list.
- Add a native file picker entry point in the app target and route selected
  files back into `SetupFlowState`.
- Support remove and move up/down controls with stable accessibility labels.
- Reload contexts after path changes are saved, and keep missing saved
  watchlists out of selectable context entries without deleting them.
- Update runtime docs and canonical vocabulary.
- Run the full quality gate after focused tests pass.

**Manual/HITL check when practical:**
- Launch the visible app with `./scripts/compile-and-run.sh`.
- Open Settings and confirm App Settings shows kubeconfig path controls.
- Use the file picker to add a kubeconfig file and confirm context tabs reload.

**failure_behavior:** If native file picker wiring is blocked by macOS sandbox
or testability constraints, keep the model/service behavior and replan the UI
entry point rather than shipping a half-working Settings control.

**security_considerations:** Settings may display selected local path strings.
It must not preview kubeconfig file contents or expose command output.
