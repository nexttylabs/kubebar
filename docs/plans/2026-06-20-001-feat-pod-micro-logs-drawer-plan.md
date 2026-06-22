---
title: "feat: add Pod Micro-Logs Drawer"
type: feat
status: planned
date: 2026-06-20
origin: .imm/specs/2026-06-20-pod-micro-logs-drawer.md
---

# feat: add Pod Micro-Logs Drawer

## Summary

- Summary: Add a bounded live `kubectl logs --tail=100 -f` Sheet for `Bad` Pod
  rows with copy and simple search.

This plan implements the user-confirmed full feature in one outcome unit. The
scope is intentionally bounded around a single user-opened Bad Pod log drawer
so Kubebar stays a glanceable health tool rather than becoming a full log
console.

## Current Slice

- Roadmap source: none
- Execution scope: Pod row log affordance, display-model target identity,
  live kubectl log stream boundary, ViewModel lifecycle state, SwiftUI Sheet UI,
  runtime invariants, and tests
- Deferred phases: explicit multi-container selection, previous-container logs,
  saved log history, cross-Pod aggregation, and advanced search syntax remain
  outside this plan
- This is not a general Kubernetes logging roadmap.

## Task

- Type: feat
- Scope: Pods tab, display model, live kubectl process boundary, menu ViewModel,
  tests/docs
- Owner: imm-work
- Verification: focused Swift tests and full Swift quality gate

## Output Language

User-facing assistant replies remain Chinese per current conversation
preference. Project planning documents remain English by default to match this
repository's durable documentation convention. Code identifiers, commands,
schema fields, paths, `Step`, `Plan`, `Spec`, and `Verification` remain literal.

## Origin

The user requested `Pod Micro-Logs Drawer`: when a Watchlist Pod is `Bad`
because of states such as `CrashLoop` or `Error`, show a log icon on the Pod
row; clicking it opens a clean read-only SwiftUI Sheet showing recent logs from
`kubectl logs --tail=100 -n <namespace> <pod-name>` with copy and keyword
search. After review, the user rejected a non-streaming first slice and asked
for the full realtime feature.

## Research

- `CONTEXT.md` defines `Pod Micro-Logs Drawer` as temporary troubleshooting UI,
  not Health category input.
- `docs/architecture/runtime-invariants.md` requires UI to render
  `MenuDisplayModel`, keeps `HealthEvaluator` as severity source of truth,
  requires app-owned context and effective kubeconfig for kubectl reads, and
  forbids stale data looking current.
- `Kubebar/Views/PodsTabView.swift` renders namespace sections and Pod rows;
  `PodRowView` is the natural location for a compact Bad-row log affordance.
- `KubebarCore/Models/MenuDisplayModel.swift` owns `PodItemDisplay`, the
  display-ready data that the Pods tab uses.
- `KubebarCore/Services/HealthEvaluator.swift` maps `PodDetail` into
  `PodItemDisplay` and already decides Pod row state from failed, waiting, and
  terminated reasons.
- `KubebarCore/Services/CommandRunner.swift` owns process launch environment
  and PATH normalization for finite commands, but its `run()` API reads to end
  and is not appropriate for `kubectl logs -f`; this plan needs a separate
  injectable streaming boundary that reuses the same launch environment
  behavior.
- `Kubebar/MenuBarViewModel.swift` owns active app config, selected context,
  context switching, refresh invalidation, and task cancellation; it should own
  the active log drawer target and cancel the stream when app-owned context or
  target changes.
- `docs/solutions/rejected-decisions/pod-resource-history-alerting-2026-05-14.md`
  previously rejected historical Pod resource charts, storage, and alerts
  because they would move Kubebar toward dashboard behavior. This plan avoids
  storage, alerting, and Health category changes.
- Planner subagent dispatch was not used: `imm_activation_plan` returned no
  candidates and `solo_fallback_reason: trigger_not_hit`.

## Decisions

- Implement a bounded live micro-log drawer, not a full log console.
- Use `kubectl logs --tail=100 -f -n <namespace> <pod-name> --context <context>`
  semantics for the initial implementation.
- Introduce a dedicated injectable log streaming service instead of extending
  `CommandRunning.run()` to cover never-ending streams.
- Reuse `ProcessCommandRunner.launchEnvironment` and `KubectlEnvironment` for
  PATH and `KUBECONFIG` behavior.
- Keep only an in-memory bounded buffer, with a target cap of 1000 lines.
- Show log affordance only from fresh display-model Pod rows that are `Bad`.
- Keep search local to the buffer and copy limited to current visible log text.
- Treat multi-container errors as safe failure text for this slice rather than
  adding a container picker.

## Assumptions

- A single Pod target is enough for this feature because Pod rows already carry
  namespace and Pod name.
- `kubectl logs` safe stderr can be summarized without exposing the full
  command or raw transcripts.
- Line-based buffering is sufficient for Kubernetes logs in this menu utility.
- Closing a Sheet is the expected user action for stopping live logs.
- `swift test` can cover the streaming service with a fake streaming boundary;
  full process-level behavior can be covered with focused service tests and the
  quality gate.

## Planning Quality Gate Notes

- Contract surface: `CONTEXT.md`,
  `docs/architecture/runtime-invariants.md`,
  `KubebarCore/Models/MenuDisplayModel.swift`,
  `KubebarCore/Services/HealthEvaluator.swift`,
  `KubebarCore/Services/CommandRunner.swift`,
  a new log streaming service under `KubebarCore/Services/`,
  `Kubebar/MenuBarViewModel.swift`, `Kubebar/Views/MenuBarRootView.swift`,
  `Kubebar/Views/PodsTabView.swift`, and related tests.
- Compatibility: no persisted data migration is needed; new fields must keep
  existing test fixtures easy to construct through defaulted initializers.
- Interruption recovery: if execution stops after model/service work, the app
  can still build only if UI wiring is complete; executor should keep changes
  in one coherent patch and run focused tests before handoff.
- Rollback path: revert the new log service, display-model additions, Pods tab
  Sheet wiring, ViewModel state, tests, and runtime-invariants update together.
- Verification strength: service and ViewModel tests must fail on missing
  `--context`, missing `KUBECONFIG`, missing cancellation, unbounded buffers,
  or log buttons appearing on non-Bad rows; UI smoke/build is supplemental.
- Brainstorm traceability: the user confirmed the full realtime feature in
  conversation rather than via a persisted Brainstorm manifest, so there are no
  `BR-*` IDs to map in this plan.

## Devil's Advocate Audit

- Rollback resilience: This is one user-visible outcome with tightly coupled
  model, service, ViewModel, and UI changes. Keeping it as one step avoids a
  half-shipped log button with no safe stream or a service with no UI path.
  Rollback is coherent because the feature does not mutate Kubernetes resources
  or persisted app config.
- Verification vanity: The plan does not rely on label-existence checks. Tests
  must inspect generated kubectl arguments/environment, fake stream lifecycle,
  cancellation behavior, bounded buffering, and row-state gating.
- Spec dilution detection: The plan preserves the user's "do not narrow"
  request by including live `-f`, copy, search, and Sheet UI. It explicitly
  defers only adjacent expansions that were not requested, such as history,
  aggregation, alerts, previous-container logs, and full container selection.

## Scope Boundaries

- In scope: `Bad` Pod log affordance, native Sheet drawer, live `kubectl logs`
  stream, cancellation, bounded buffer, copy, local search, safe errors,
  app-owned context/kubeconfig, tests, and runtime documentation.
- Out of scope: stored logs, alerting, Health category changes, Secret reads,
  resource mutation, kubeconfig current-context mutation, cross-Pod log views,
  previous-container logs, advanced search, and k9s replacement behavior.

## Deferred Work

- Add explicit container selection when a multi-container Pod needs it.
- Add previous-container logs for crash-loop diagnosis if users need it.
- Add a richer search UI only if simple keyword search proves insufficient.
- Consider an "Open in k9s logs" handoff in a separate k9s-specific slice.

## Implementation Units

### Step 1

- Step ID: U1
- Result: Bad Pod rows open a bounded live Pod Micro-Logs Drawer.
- Verification: swift test --filter MenuDisplayModelTests && swift test --filter CommandRunnerTests && swift test --filter PodLogStream && swift test --filter MenuBarViewModelTests && /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/swift-quality-gate.sh local && rtk git diff --check
- Depends on: None
- Test scenarios: Bad Pod rows expose a log target; ready and watch Pod rows do not expose a log target; log stream request includes logs tail follow namespace pod and app-owned context; explicit kubeconfig paths flow into the log stream environment; closing or replacing the drawer cancels the stream; the log buffer caps retained lines; copy returns current buffer text; search reports local keyword matches; safe failure text is shown without raw command transcript

**Goal:** Deliver the full user-visible Pod Micro-Logs Drawer as one coherent
feature.

**Verification type:** automated

**Execution note:** test-first

**Requirements:** R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14

**Dependencies:** None

**Discovery cache:**
- `Kubebar/Views/PodsTabView.swift` (Pod row UI and Sheet entry point)
- `Kubebar/Views/MenuBarRootView.swift` (root menu Sheet ownership)
- `Kubebar/MenuBarViewModel.swift` (app-owned context, config, cancellation)
- `KubebarCore/Models/MenuDisplayModel.swift` (display-ready Pod log target)
- `KubebarCore/Services/HealthEvaluator.swift` (Pod row state mapping)
- `KubebarCore/Services/CommandRunner.swift` (launch environment and new streaming boundary pattern)
- `KubebarTests/Models/MenuDisplayModelTests.swift` (display model fixtures)
- `KubebarTests/Services/CommandRunnerTests.swift` (environment and process behavior)
- `KubebarTests/Services/KubectlClusterReaderTests.swift` (kubectl request test patterns)
- `docs/architecture/runtime-invariants.md` (product/runtime contract)

**Parallel probes:**
- Probe 1: scope `Kubebar/Views/PodsTabView.swift`, `Kubebar/Views/MenuBarRootView.swift`; output concise UI wiring notes for Sheet ownership, accessibility, and menu height risks; readonly true.
- Probe 2: scope `KubebarCore/Services/CommandRunner.swift`, service tests; output concise process streaming and cancellation notes; readonly true.
- Probe 3: scope `Kubebar/MenuBarViewModel.swift`, `KubebarCore/Models/MenuDisplayModel.swift`, `HealthEvaluator.swift`; output concise state ownership and context-change cancellation notes; readonly true.

**Files:**
- Modify: `CONTEXT.md`
- Modify: `docs/architecture/runtime-invariants.md`
- Modify: `KubebarCore/Models/MenuDisplayModel.swift`
- Modify: `KubebarCore/Services/HealthEvaluator.swift`
- Modify: `KubebarCore/Services/CommandRunner.swift`
- Add: `KubebarCore/Services/PodLogStreamer.swift`
- Modify: `Kubebar/MenuBarViewModel.swift`
- Modify: `Kubebar/Views/MenuBarRootView.swift`
- Modify: `Kubebar/Views/PodsTabView.swift`
- Modify/Add: focused tests under `KubebarTests/Models/`, `KubebarTests/Services/`, and `KubebarTests/`

**Approach:**
- Add a small `PodLogTarget`/log-target display value to `PodItemDisplay`,
  populated only when the evaluated Pod row state is `.bad`.
- Add an injectable Pod log streaming service that launches `kubectl logs`
  with app-owned context, effective kubeconfig, tail count, follow mode, and a
  cancellation-safe process lifecycle.
- Add ViewModel state for active drawer target, log stream status, bounded
  buffer, search query/matches, copy text, and cancellation when the Sheet
  closes or context changes.
- Add a compact log button to `PodRowView` and present a SwiftUI Sheet from the
  root menu surface so the row stays short.
- Keep the drawer visually plain: title with namespace/Pod, status line,
  search field, copy button, and read-only monospaced log text.
- Update runtime invariants to document the bounded user-opened log surface.

**failure_behavior:** If the streaming boundary cannot be made cancellation
safe, stop and replan before shipping a `-f` process that can outlive the
drawer.

**security_considerations:** Logs can contain sensitive application data. Do
not persist or transmit them; copy only when the user clicks Copy; do not show
the raw command transcript; do not read Kubernetes Secrets; keep all data local
to the app process.
