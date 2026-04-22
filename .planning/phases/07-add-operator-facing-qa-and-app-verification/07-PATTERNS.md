# Phase 07: Add Operator-Facing QA and App Verification - Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 12 likely new/modified paths
**Analogs found:** 11 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `KubebarCore/QA/MenuStateFixtureCatalog.swift` | utility / fixture catalog | transform | `KubebarTests/Models/MenuDisplayModelTests.swift` | data-flow-match |
| `Kubebar/QA/QALaunchMode.swift` | utility / config adapter | event-driven | `Kubebar/KubebarApp.swift` + `Kubebar/MenuBarViewModel.swift` | role-match |
| `KubebarTests/QA/MenuStateFixtureCatalogTests.swift` | test | transform | `KubebarTests/Models/MenuDisplayModelTests.swift` | exact |
| `scripts/generate-qa-evidence.sh` | utility script | file-I/O / batch | `scripts/swift-quality-gate.sh` | role-match |
| `scripts/swift-quality-gate.sh` | gate script | batch | `scripts/swift-quality-gate.sh` | exact |
| `scripts/compile-and-run.sh` | smoke script | process I/O | `scripts/compile-and-run.sh` | exact |
| `.planning/phases/07-add-operator-facing-qa-and-app-verification/07-UAT.md` | docs / test evidence | manual file-I/O | `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md` | exact |
| `docs/qa/operator-verification.md` | docs | manual checklist | `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md` | role-match |
| `docs/assets/qa/` | asset directory | file-I/O | none | no-analog |
| `docs/architecture/README.md` | docs index | static reference | `docs/architecture/README.md` | exact |
| `Package.swift` | build config | build graph | `Package.swift` | exact / likely no edit |
| `project.yml` | build config | build graph | `project.yml` | exact / likely no edit |

## Pattern Assignments

### `KubebarCore/QA/MenuStateFixtureCatalog.swift` (utility / fixture catalog, transform)

**Analog:** `KubebarTests/Models/MenuDisplayModelTests.swift`

**Supporting analogs:** `KubebarCore/Models/MenuDisplayModel.swift`, `KubebarCore/Models/ClusterSnapshot.swift`, `KubebarCore/Services/HealthEvaluator.swift`, `KubebarCore/Models/SetupFlowState.swift`, `KubebarCore/Models/WatchlistSelectionState.swift`

**Imports pattern** (`KubebarCore/Models/MenuDisplayModel.swift` lines 1-2):
```swift
import Foundation
```

Keep the catalog pure Swift/Core. Do not import SwiftUI, shell APIs, or app UI types.

**Core value type pattern** (`KubebarCore/Models/MenuDisplayModel.swift` lines 103-140):
```swift
public struct MenuDisplayModel: Equatable, Sendable {
    public let state: ClusterHealthState
    public let contextName: String
    public let healthSentence: String
    public let primaryStatusReason: String
    public let lastUpdated: String
    public let counters: MenuCounters
    public let warningEventSummaries: [WarningEventDisplay]
    public let sectionNotices: [SectionAvailabilityDisplay]
    public let visibleWatchItems: [WatchItemDisplay]
    public let hiddenWatchItemCount: Int
    public let staleBanner: StaleBannerDisplay?
}
```

Copy the local style: public structs/enums, `Equatable`, `Sendable`, explicit initializers, no reference types unless needed.

**State enum pattern** (`KubebarCore/Models/ClusterHealthState.swift` lines 3-20):
```swift
public enum ClusterHealthState: Int, Codable, Sendable {
    case ok = 0
    case watch = 1
    case bad = 2
    case stale = 3

    public var label: String {
        switch self {
        case .ok:
            "OK"
        case .watch:
            "Watch"
        case .bad:
            "Bad"
        case .stale:
            "Stale"
        }
    }
}
```

The QA state enum should be exhaustive and case-iterable. Do not add product health states beyond OK, Watch, Bad, and Stale.

**Snapshot fixture construction pattern** (`KubebarTests/Models/MenuDisplayModelTests.swift` lines 7-30):
```swift
@Test("healthy snapshots show OK status and compact counters")
func healthySnapshotShowsOKStatusAndCounters() {
    let snapshot = ClusterSnapshot(
        contextName: "prod",
        nodeSummary: NodeSummary(ready: 3, total: 3),
        podSummary: PodSummary(running: 12, total: 12),
        warningEventCount: 0,
        trackedItems: [
            TrackedItemStatus(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "6/6 pods running")
        ],
        capturedAt: Date(timeIntervalSince1970: 100)
    )

    let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
}
```

Use fixed dates and app-owned display strings. Avoid live cluster state.

**Watch / warning-state fixture pattern** (`KubebarTests/Models/MenuDisplayModelTests.swift` lines 55-72):
```swift
let snapshot = ClusterSnapshot(
    contextName: "prod",
    nodesSection: .available(NodeSummary(ready: 3, total: 3)),
    podsSection: .available(PodSummary(running: 12, total: 12)),
    warningEventsSection: .available([
        warningEvent(reason: "BackOff", observedAt: Date(timeIntervalSince1970: 100), count: 2)
    ]),
    workloadsSection: .available([]),
    capturedAt: Date(timeIntervalSince1970: 100)
)

let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
```

Use warning events for Watch, matching Phase 07 D-06.

**Bad-state fixture pattern** (`KubebarTests/Models/MenuDisplayModelTests.swift` lines 74-89):
```swift
let snapshot = ClusterSnapshot(
    contextName: "prod",
    nodesSection: .available(NodeSummary(ready: 2, total: 3)),
    podsSection: .available(PodSummary(running: 12, total: 12)),
    warningEventsSection: .available([]),
    workloadsSection: .available([]),
    capturedAt: Date(timeIntervalSince1970: 100)
)

let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
```

Use a not-ready node or bad workload for Bad, matching Phase 07 D-07.

**Stale refresh-failure pattern** (`KubebarTests/Models/MenuDisplayModelTests.swift` lines 200-227):
```swift
let display = HealthEvaluator().evaluate(
    snapshot: nil,
    previousSnapshot: previous,
    failure: RefreshFailure(reason: "kubectl timed out"),
    now: Date(timeIntervalSince1970: 250)
)

#expect(display.state == .stale)
#expect(display.contextName == "prod")
#expect(display.staleBanner?.reason == "kubectl timed out")
#expect(display.visibleWatchItems.first?.title == "api/checkout")
```

Use retained previous data plus Stale state for kubectl failure evidence.

**Stale age-out pattern** (`KubebarTests/Models/MenuDisplayModelTests.swift` lines 229-255):
```swift
let display = HealthEvaluator().evaluate(
    snapshot: snapshot,
    now: Date(timeIntervalSince1970: 221),
    staleAfterSeconds: 120
)

#expect(display.state == .stale)
#expect(display.staleBanner?.reason == "Last refresh is too old")
#expect(display.primaryStatusReason == "Last refresh is too old")
```

Keep age-out separate from refresh failure.

**First-use / empty-watchlist distinction pattern** (`KubebarCore/Models/SetupFlowState.swift` lines 33-39, `KubebarCore/Models/WatchlistSelectionState.swift` lines 30-40):
```swift
public var isConfigured: Bool {
    selectedContext != nil && !watchlist.isEmpty
}

public var needsSetup: Bool {
    !isConfigured
}
```

```swift
public var emptyStateTitle: String {
    hasAvailableTargets ? "No watch targets selected" : "No watch targets available"
}

public var emptyStateMessage: String {
    if hasAvailableTargets {
        "Choose namespaces or workloads to keep Kubebar focused on the first screen."
    } else {
        "Choose a cluster context or retry loading watch targets."
    }
}
```

Represent first-use as setup incomplete. Represent empty-watchlist as a selected context with no selected targets.

**Sanitization / sensitive text pattern** (`KubebarTests/Services/KubectlClusterReaderTests.swift` lines 184-204):
```swift
@Test("warning event failure reasons redact paths and token text")
func warningEventFailureReasonsRedactPathsAndTokenText() throws {
    let pathRunner = FakeMultiCommandRunner(results: [
        warningEventsCommand: CommandResult(output: "", error: "open /Users/example/.kube/config: permission denied", exitCode: 1)
    ])
    let tokenRunner = FakeMultiCommandRunner(results: [
        warningEventsCommand: CommandResult(output: "", error: "token expired for cluster", exitCode: 1)
    ])

    #expect(pathSnapshot.warningEventsSection.unavailableReason == "open ~/.kube/config: permission denied")
    #expect(tokenSnapshot.warningEventsSection.unavailableReason == "kubectl failed")
}
```

Fixture metadata and generated UAT must not contain raw kubeconfig paths, tokens, command transcripts, or full JSON.

---

### `Kubebar/QA/QALaunchMode.swift` (utility / config adapter, event-driven)

**Analog:** `Kubebar/KubebarApp.swift`

**Supporting analog:** `Kubebar/MenuBarViewModel.swift`

**Imports pattern** (`Kubebar/KubebarApp.swift` lines 1-2):
```swift
import SwiftUI
import KubebarCore
```

If `QALaunchMode` is a pure parser, prefer `Foundation` + `KubebarCore`; only import SwiftUI in app/view files.

**Menu shell wiring pattern** (`Kubebar/KubebarApp.swift` lines 4-34):
```swift
@main
struct KubebarApp: App {
    @StateObject private var viewModel = MenuBarViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(
                display: viewModel.display,
                setupState: $viewModel.setupState,
                isShowingSetup: viewModel.isShowingSetup,
                refreshCadence: viewModel.refreshCadence,
                isRefreshing: viewModel.isRefreshing,
                onRefresh: viewModel.refreshNow,
                onEditWatchlist: viewModel.openSetup,
                onCompleteSetup: viewModel.completeSetup,
                onSelectContext: viewModel.selectSetupContext,
                onSelectRefreshCadence: viewModel.selectRefreshCadence,
                onRetryTargets: viewModel.retryWatchTargetLoad
            )
        } label: {
            let presentation = MenuBarStatusPresentation(state: viewModel.display.state)
            switch presentation.icon {
            case let .system(name):
                Label(presentation.accessibilityLabel, systemImage: name)
            case let .custom(name):
                Image(name)
                    .accessibilityLabel(presentation.accessibilityLabel)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
```

QA launch mode should feed the same `MenuBarRootView` and `MenuBarStatusPresentation` path. Do not add visible production controls for switching QA states.

**View model dependency-injection pattern** (`Kubebar/MenuBarViewModel.swift` lines 36-47):
```swift
init(
    configStore: AppConfigStore = AppConfigStore(directory: MenuBarViewModel.defaultConfigDirectory),
    refreshCoordinator: RefreshCoordinator = RefreshCoordinator(),
    contextCatalog: ContextCatalog = ContextCatalog(),
    watchTargetCatalog: any WatchTargetCataloging = WatchTargetCatalog(),
    now: Date = Date()
) {
    self.configStore = configStore
    self.refreshCoordinator = refreshCoordinator
    self.contextCatalog = contextCatalog
    self.watchTargetCatalog = watchTargetCatalog
}
```

If QA mode affects initialization, add it as an explicit injected value or a small adapter around environment/arguments. Avoid singletons.

**Initial display pattern** (`Kubebar/MenuBarViewModel.swift` lines 215-226):
```swift
private static func initialDisplay(for config: AppConfig, now: Date) -> MenuDisplayModel {
    let reason = config.needsSetup
        ? "Choose a cluster context and watchlist to begin"
        : "Waiting for first refresh"

    return HealthEvaluator().evaluate(
        snapshot: nil,
        previousSnapshot: nil,
        failure: RefreshFailure(reason: reason),
        now: now
    )
}
```

For first-use QA, use the same setup/initial-display behavior rather than making UI decide health.

**Async side-effect pattern** (`Kubebar/MenuBarViewModel.swift` lines 103-122):
```swift
Task {
    defer {
        let shouldRunPendingRefresh = refreshGate.finishAndConsumePendingRefresh()
        isRefreshing = false

        if shouldRunPendingRefresh {
            performRefresh(queueIfBusy: false)
        }
    }

    let result = await Task.detached(priority: .userInitiated) {
        refreshCoordinator.refresh(config: config, previousSnapshot: previousSnapshot, now: Date())
    }.value

    guard refreshGate.shouldApply(ticket, currentConfig: self.config) else {
        return
    }

    applyRefreshResult(result)
}
```

QA launch mode should avoid this path when displaying fixtures. It should not shell out or mutate config.

---

### `KubebarTests/QA/MenuStateFixtureCatalogTests.swift` (test, transform)

**Analog:** `KubebarTests/Models/MenuDisplayModelTests.swift`

**Supporting analogs:** `KubebarTests/Services/KubectlClusterReaderTests.swift`, `KubebarTests/Models/SetupFlowStateTests.swift`, `KubebarTests/Models/MenuBarStatusPresentationTests.swift`

**Imports pattern** (`KubebarTests/Models/MenuDisplayModelTests.swift` lines 1-3):
```swift
import Foundation
import Testing
@testable import KubebarCore
```

Use `Foundation` when tests need fixed dates.

**Suite / test pattern** (`KubebarTests/Models/MenuDisplayModelTests.swift` lines 5-8):
```swift
@Suite("Menu display model")
struct MenuDisplayModelTests {
    @Test("healthy snapshots show OK status and compact counters")
    func healthySnapshotShowsOKStatusAndCounters() {
```

Use `@Suite`, `@Test`, and `#expect`. Do not introduce XCTest.

**Assertion style pattern** (`KubebarTests/Models/MenuBarStatusPresentationTests.swift` lines 6-22):
```swift
@Test("maps health states to distinct symbols and labels")
func mapsHealthStatesToDistinctSymbolsAndLabels() {
    #expect(MenuBarStatusPresentation(state: .ok).icon == .custom("KubebarLogo"))
    #expect(MenuBarStatusPresentation(state: .watch).icon == .system("exclamationmark.triangle"))
    #expect(MenuBarStatusPresentation(state: .bad).icon == .system("xmark.octagon"))
    #expect(MenuBarStatusPresentation(state: .stale).icon == .system("clock.badge.exclamationmark"))

    #expect(MenuBarStatusPresentation(state: .ok).accessibilityLabel == "Kubebar OK")
    #expect(MenuBarStatusPresentation(state: .watch).accessibilityLabel == "Kubebar Watch")
    #expect(MenuBarStatusPresentation(state: .bad).accessibilityLabel == "Kubebar Bad")
    #expect(MenuBarStatusPresentation(state: .stale).accessibilityLabel == "Kubebar Stale")
}
```

Add fixture tests for all required QA states: Healthy, Watch, Bad, Stale refresh failure, Stale age-out, first-use, empty-watchlist, and kubectl failure.

**Throws expectation pattern** (`KubebarTests/Services/KubectlClusterReaderTests.swift` lines 68-87):
```swift
@Test("kubectl timeout reports short timeout reason")
func kubectlTimeoutReportsShortTimeoutReason() {
    let reader = KubectlClusterReader(runner: ThrowingCommandRunner(error: CommandRunnerError.timedOut))

    #expect(throws: KubectlCommandError.failed("kubectl timed out")) {
        try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date())
    }
}
```

For invalid fixture names or generator inputs, prefer explicit errors and `#expect(throws:)`.

**First-use / empty-watchlist tests** (`KubebarTests/Models/SetupFlowStateTests.swift` lines 6-21, 58-70):
```swift
@Test("missing context or watchlist keeps setup active")
func missingContextOrWatchlistKeepsSetupActive() {
    let state = SetupFlowState(
        selectedContext: nil,
        availableContexts: ["prod"],
        watchlist: WatchlistSelectionState(
            availableNamespaces: ["api"],
            availableWorkloads: [.workload(namespace: "api", name: "checkout", kind: .deployment)]
        )
    )

    #expect(state.needsSetup)
    #expect(state.title == "Set up Kubebar")
}
```

```swift
@Test("available targets alone do not complete setup")
func availableTargetsAloneDoNotCompleteSetup() {
    let state = SetupFlowState(
        selectedContext: "prod",
        watchlist: WatchlistSelectionState(
            availableNamespaces: ["api"],
            availableWorkloads: [.workload(namespace: "api", name: "checkout", kind: .deployment)]
        )
    )

    #expect(!state.isConfigured)
}
```

Keep first-use and empty-watchlist separate in fixture coverage.

**Test helper / fake pattern** (`KubebarTests/Services/KubectlClusterReaderTests.swift` lines 342-351, 423-441):
```swift
private final class FakeMultiCommandRunner: CommandRunning, @unchecked Sendable {
    private let results: [[String]: CommandResult]

    init(results: [[String]: CommandResult]) {
        self.results = results
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        results[request.arguments] ?? CommandResult(output: "", error: "unexpected command", exitCode: 1)
    }
}
```

```swift
private func readSnapshot(
    pods: String,
    warningEvents: String,
    workloadMetadata: String = deploymentMetadataJSON,
    watchTargets: [WatchTarget]
) throws -> ClusterSnapshot {
    let runner = FakeMultiCommandRunner(results: [
        nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
        podsCommand: CommandResult(output: pods, error: "", exitCode: 0),
        warningEventsCommand: CommandResult(output: warningEvents, error: "", exitCode: 0),
        deploymentsCommand: CommandResult(output: workloadMetadata, error: "", exitCode: 0)
    ])

    return try KubectlClusterReader(runner: runner).readSnapshot(
        contextName: "prod",
        watchTargets: watchTargets,
        now: Date(timeIntervalSince1970: 100)
    )
}
```

Use fake inputs for kubectl failure proof; do not require a real broken cluster.

---

### `scripts/generate-qa-evidence.sh` (utility script, file-I/O / batch)

**Analog:** `scripts/swift-quality-gate.sh`

**Supporting analog:** `scripts/compile-and-run.sh`

**Shell header / root pattern** (`scripts/swift-quality-gate.sh` lines 1-7):
```bash
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-local}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
```

New scripts should use the same strict shell header and repo-root resolution.

**Function pattern** (`scripts/swift-quality-gate.sh` lines 12-17):
```bash
find_candidates() {
  local pattern="$1"
  find . \
    \( -path './Pods' -o -path './Carthage' -o -path './DerivedData' -o -path './.build' \) -prune -o \
    -name "$pattern" -print | sort
}
```

Prefer small named functions and `local` variables.

**Output validation pattern** (`scripts/compile-and-run.sh` lines 21-24):
```bash
if [ ! -d "$APP_PATH" ]; then
  echo "Built app not found: $APP_PATH" >&2
  exit 1
fi
```

The generator should fail if the output directory is missing, the generated file is empty, or required rows are absent.

**Evidence output contract pattern** (`scripts/compile-and-run.sh` lines 42-50):
```bash
echo "Launching ${APP_PATH}"
open -n "$APP_PATH"

for _ in $(seq 1 50); do
  pid="$(pgrep -x "$APP_NAME" | head -n 1 || true)"
  if [ -n "$pid" ]; then
    echo "${APP_NAME} is running with PID ${pid}"
    echo "App path: ${APP_PATH}"
    exit 0
  fi
done
```

Generated QA evidence should print concise app-owned facts and paths, not raw command output.

**Required generated content pattern:** use the Phase 07 rows from `07-CONTEXT.md` lines 43-53 and `07-VALIDATION.md` lines 71-76:
```markdown
| State | Result | Reproduction steps | Expected behavior | Observed behavior | Evidence path | Limitations | Follow-up risk |
| Healthy | pending-human-verification | Launch with Healthy QA state. | Opened menu shows OK/healthy state without stale or warning language. | pending-human-verification | docs/assets/qa/phase-07-healthy.png | Visible menu capture may require human action. | Must not mark passed without evidence. |
```

Keep screenshots as paths and allow `pending-human-verification` where capture is blocked.

---

### `scripts/swift-quality-gate.sh` (gate script, batch)

**Analog:** `scripts/swift-quality-gate.sh`

**Existing mode / env pattern** (lines 4-10):
```bash
MODE="${1:-local}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

CONFIGURATION="${XCODE_CONFIGURATION:-Debug}"
DESTINATION="${XCODE_DESTINATION:-platform=macOS}"
DERIVED_DATA_PATH="${XCODE_DERIVED_DATA_PATH:-DerivedData}"
```

Add QA generation without changing the existing entrypoint or Xcode/SwiftPM environment variables.

**Xcode checks pattern** (lines 140-156):
```bash
echo "Running Xcode build check"
xcodebuild "$container_flag" "$container_path" \
  -scheme "$scheme" \
  -configuration "$CONFIGURATION" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build \
  CODE_SIGNING_ALLOWED=NO

echo "Running Xcode test check"
xcodebuild "$container_flag" "$container_path" \
  -scheme "$scheme" \
  -configuration "$CONFIGURATION" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  test \
  CODE_SIGNING_ALLOWED=NO
```

Do not remove or weaken these checks.

**SwiftPM checks pattern** (lines 63-69):
```bash
run_swift_package_checks() {
  echo "Using Swift Package Manager quality gate"
  echo "Running Swift build check"
  swift build
  echo "Running Swift test check"
  swift test
}
```

Keep SwiftPM build/test intact. Add QA artifact generation as an additional function.

**Main ordering pattern** (lines 159-173):
```bash
main() {
  echo "Swift quality gate mode: $MODE"

  run_xcode_checks

  if [ -f "Package.swift" ]; then
    run_swift_package_checks
    return 0
  fi

  if ! find . -maxdepth 3 \( -name '*.xcworkspace' -o -name '*.xcodeproj' \) | grep -q .; then
    echo "No Xcode workspace/project or Package.swift found." >&2
    return 1
  fi
}
```

Recommended addition: run `run_qa_artifact_check` after SwiftPM checks and before returning. The check should generate into a temp directory and validate required rows, not overwrite committed `07-UAT.md`.

---

### `scripts/compile-and-run.sh` (smoke script, process I/O)

**Analog:** `scripts/compile-and-run.sh`

**Build invocation pattern** (lines 13-20):
```bash
echo "Building and testing ${APP_NAME}"
XCODE_WORKSPACE="" \
  XCODE_PROJECT="${XCODE_PROJECT:-Kubebar.xcodeproj}" \
  XCODE_SCHEME="${XCODE_SCHEME:-Kubebar}" \
  XCODE_CONFIGURATION="$CONFIGURATION" \
  XCODE_DERIVED_DATA_PATH="$DERIVED_DATA_PATH" \
  ./scripts/swift-quality-gate.sh local
```

Keep this as the visible-app smoke path. If QA state launch is added, use environment variables without bypassing the quality gate.

**Process cleanup pattern** (lines 26-40):
```bash
echo "Quitting existing ${APP_NAME} instance if present"
osascript -e "tell application id \"${BUNDLE_ID}\" to quit" >/dev/null 2>&1 || true

for _ in $(seq 1 20); do
  if ! pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  while IFS= read -r pid; do
    [ -n "$pid" ] && kill "$pid"
  done < <(pgrep -x "$APP_NAME")
fi
```

Refinements should preserve existing cleanup behavior.

**Evidence output pattern** (lines 45-50):
```bash
for _ in $(seq 1 50); do
  pid="$(pgrep -x "$APP_NAME" | head -n 1 || true)"
  if [ -n "$pid" ]; then
    echo "${APP_NAME} is running with PID ${pid}"
    echo "App path: ${APP_PATH}"
    exit 0
  fi
done
```

If evidence logging is refined, keep app path, PID, and running state as the visible-app evidence contract.

---

### `.planning/phases/07-add-operator-facing-qa-and-app-verification/07-UAT.md` (docs / test evidence, manual file-I/O)

**Analog:** `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md`

**Frontmatter pattern** (lines 1-9):
```markdown
---
status: pending-human-verification
phase: 06-polish-menu-bar-icon-states-and-keyboard-navigation
source:
  - 06-01-SUMMARY.md
  - 06-02-SUMMARY.md
started: 2026-04-21T16:13:52Z
updated: 2026-04-21T16:16:35Z
---
```

Use `pending-human-verification` when screenshots or visible menu traversal are not complete.

**Automated verification table pattern** (lines 11-20):
```markdown
## Automated Verification

| Check | Result | Evidence |
| --- | --- | --- |
| `swift test --filter MenuBarStatusPresentationTests` | pass | The Menu bar status presentation suite passed 1 test, covering the four menu bar status labels and icon sources. |
| `./scripts/swift-quality-gate.sh local` | pass | Xcode build, Xcode test, SwiftPM build, and SwiftPM test passed; the full Swift test run reported 86 tests in 15 suites. |
| `./scripts/compile-and-run.sh` | pass | The visible-app smoke path rebuilt and tested the app, then launched `DerivedData/Build/Products/Debug/Kubebar.app` with PID 27388. |
```

For Phase 07, add generator output and fixture tests here.

**Manual menu-state table pattern** (lines 21-30):
```markdown
## Manual Menu State Checks

| State | Status | Expected opened-menu behavior | Evidence |
| --- | --- | --- | --- |
| OK | pending-human-verification | Opened menu shows `OK` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic OK state presentation. |
| Watch | pending-human-verification | Opened menu shows `Watch` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic Watch state reasons. |
| Bad | pending-human-verification | Opened menu shows `Bad` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic Bad state reasons. |
| Stale | pending-human-verification | Opened menu shows `Stale` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic Stale fallback reasons. |
```

Phase 07 should expand the table columns to include reproduction steps, observed behavior, screenshot path, limitations, and follow-up risk per D-03.

**Scope guard table pattern** (lines 61-70):
```markdown
## Scope Guards

| Guard | Result | Evidence |
| --- | --- | --- |
| No AppKit status-item rewrite | pass | Source review kept the existing SwiftUI `MenuBarExtra.window` path and did not add a custom status-item shell. |
| No packaging or signing scope | pass | This phase added runtime docs and UAT only; no packaging, signing, or release workflow was added. |
| No k9s handoff | pass | No deeper-debugging handoff action was added. |
| No dashboard surface | pass | The UAT preserves the native utility menu boundary and does not introduce a dashboard surface. |
| No command transcript exposure | pass | Runtime rules and UAT evidence require app-owned display strings or redacted observations only. |
```

Copy these guards and adapt to Phase 07. Distribution, deep debugging, dashboards, and broad menu automation remain out of scope.

---

### `docs/qa/operator-verification.md` (docs, manual checklist)

**Analog:** `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md`

**Supporting analogs:** `docs/architecture/runtime-invariants.md`, `docs/architecture/system-overview.md`

**Manual-only verification pattern** (`.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-VERIFICATION.md` lines 118-142):
```markdown
#### 1. Opened Menu State Checks

**Test:** Launch the app, open the Kubebar menu, and verify OK, Watch, Bad, and Stale when each state can be exercised live.
**Expected:** State text, visible symbol, and one short reason are present; color is not the only meaning.
**Why human:** Automation could not inspect the menu-bar extra reliably.

#### 2. Keyboard Traversal

**Test:** Enable macOS Full Keyboard Access if needed, then traverse setup, Finish setup enabled/disabled, Retry now enabled/disabled, Edit watchlist, watchlist detail disclosures, warning events, secondary sections, and target-load retry.
**Expected:** Each path is reachable and usable through native keyboard navigation.
**Why human:** Source proves native controls exist; actual macOS menu focus behavior requires visible-app testing.
```

Operator docs should explain repeatable manual verification without claiming automation can inspect the menu.

**Runtime rules to cite** (`docs/architecture/runtime-invariants.md` lines 36-51, 82-95):
```markdown
- Old data never looks current.
- A successful snapshot older than `2x` the saved refresh cadence must be shown
  as `Stale`, even when its counters and watchlist rows were healthy when
  captured.
- A failed refresh may keep the previous snapshot only when the UI marks it
  `Stale`.
```

```markdown
- Timeout, command failure, malformed JSON, and no previous data are distinct
  safe reason categories.
- Timeout uses `kubectl timed out`.
- Empty or unsafe command failure output uses `kubectl failed`.
- Warning and failure states must not rely on color alone.
- Watch, Bad, and Stale must be expressed with symbol, state text, and one
  short reason; color alone is not enough.
```

Keep this doc operator-facing: state, expected visible behavior, evidence path, and when to mark `pending-human-verification`.

---

### `docs/assets/qa/` (asset directory, file-I/O)

**Analog:** none.

No existing committed `docs/assets/` or `docs/qa/` directory exists in this checkout. Create only the directory/assets required by Phase 07 evidence. Do not use app icon asset catalog patterns for documentation screenshots.

**Naming recommendation from Phase context:** `docs/assets/qa/phase-07-healthy.png`, `phase-07-watch.png`, `phase-07-bad.png`, `phase-07-stale-refresh-failure.png`, `phase-07-stale-age-out.png`, `phase-07-first-use.png`, `phase-07-empty-watchlist.png`, `phase-07-kubectl-failure.png`.

If a screenshot is blocked, keep the UAT path field as `pending-human-verification` and explain the limitation.

---

### `docs/architecture/README.md` (docs index, static reference)

**Analog:** `docs/architecture/README.md`

**Current index pattern** (lines 1-16):
```markdown
# Architecture Notes

Use this directory for Kubebar architecture notes that are too detailed for the
repo-wide quick-start guide.

Current notes:

- `system-overview.md` — major subsystems and request flow
- `runtime-invariants.md` — defaults and guarantees that must not break

Future notes can be added here when a subsystem needs more detail:

- `module-map.md` — ownership boundaries by directory or target
- `integrations.md` — external services, auth, webhooks, queues, and data flows

Keep `AGENTS.md` as the short operational contract. Put longer explanations and subsystem-specific rules here.
```

If Phase 07 adds `docs/qa/operator-verification.md`, add a short pointer without moving product rules out of `AGENTS.md` or runtime rules out of `runtime-invariants.md`.

---

### `Package.swift` (build config, build graph)

**Analog:** `Package.swift`

**Target membership pattern** (lines 15-24):
```swift
.executableTarget(
    name: "Kubebar",
    dependencies: ["KubebarCore"],
    path: "Kubebar",
    resources: [
        .process("Assets.xcassets")
    ]
),
.target(name: "KubebarCore", path: "KubebarCore"),
.testTarget(name: "KubebarCoreTests", dependencies: ["KubebarCore"], path: "KubebarTests")
```

Likely no edit needed: new files under `Kubebar/`, `KubebarCore/`, and `KubebarTests/` are already inside target paths. Edit only if the implementation chooses a path outside those target roots or adds a new target/resource.

---

### `project.yml` (build config, build graph)

**Analog:** `project.yml`

**Target source pattern** (lines 14-49):
```yaml
targets:
  Kubebar:
    type: application
    platform: macOS
    sources:
      - path: Kubebar
    dependencies:
      - target: KubebarCore

  KubebarCore:
    type: framework
    platform: macOS
    sources:
      - path: KubebarCore

  KubebarTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: KubebarTests
    dependencies:
      - target: KubebarCore
```

Likely no edit needed: XcodeGen recursively includes the target paths. If the implementation changes target membership, edit `project.yml` as the source of truth and regenerate the project.

## Shared Patterns

### Product Boundaries

**Source:** `AGENTS.md` lines 11-17

**Apply to:** all Phase 07 code, scripts, UAT, and docs

```markdown
- Keep the menu bar icon categorical: `OK`, `Watch`, `Bad`, or `Stale`.
- Keep the dropdown watchlist-first.
- Keep first-screen watchlist rows capped at `3-5` items.
- Never let stale data look healthy or current.
- Keep deep troubleshooting out of version 1.
```

Do not add a dashboard, k9s handoff, packaging/signing scope, distribution scope, or broad menu automation framework.

### Menu Rendering Contract

**Source:** `docs/architecture/system-overview.md` lines 37-51

**Apply to:** `MenuStateFixtureCatalog`, `QALaunchMode`, fixture tests, UAT docs

```markdown
The menu never asks Kubernetes directly. It reads a display model that already
includes:

- the selected context name,
- the health sentence,
- compact node, pod, and warning counts,
- visible watchlist rows,
- overflow count for hidden watched items,
- stale banner content when the last refresh is no longer fresh.

When refresh succeeds, the coordinator stores the new snapshot and the
evaluator produces a current display model. When refresh fails, the last
snapshot can still be shown, but only as stale state.
```

Fixtures should produce app-owned display models or app-owned setup state, not raw UI-only health decisions.

### State Presentation

**Source:** `KubebarCore/Models/MenuBarStatusPresentation.swift` lines 15-43

**Apply to:** fixture catalog, QA launch mode, UAT expected behavior

```swift
public var icon: IconSource {
    switch state {
    case .ok:
        .custom("KubebarLogo")
    case .watch:
        .system("exclamationmark.triangle")
    case .bad:
        .system("xmark.octagon")
    case .stale:
        .system("clock.badge.exclamationmark")
    }
}

public var accessibilityLabel: String {
    "Kubebar \(state.label)"
}
```

UAT should verify the same four labels and symbols in the real menu.

### Watchlist-First UI Order

**Source:** `Kubebar/Views/MenuBarRootView.swift` lines 37-51

**Apply to:** QA screenshots, UAT expectations, operator verification docs

```swift
private var menuContent: some View {
    VStack(alignment: .leading, spacing: 14) {
        StatusSummaryView(display: display)
        StaleBannerView(banner: display.staleBanner)
        CompactCountersView(counters: display.counters)
        WatchlistSectionView(display: display)
        WarningEventsView(count: display.counters.warningEvents, summaries: display.warningEventSummaries, sectionNotices: display.sectionNotices)
        NodeDetailsView(summary: display.counters.nodes)
        Divider()
        refreshControls
        actions
    }
    .frame(width: 340)
    .padding(16)
}
```

Screenshots and expected behavior should preserve this ordering and avoid dashboard expansion.

### Stale Safety

**Source:** `HealthEvaluator.swift` lines 20-58 and `runtime-invariants.md` lines 36-51

**Apply to:** stale fixtures, kubectl failure fixture, tests, UAT

```swift
if let previousSnapshot {
    return displayModel(
        from: previousSnapshot,
        stateOverride: .stale,
        failureReason: failure?.reason,
        now: now,
        staleAfterSeconds: staleAfterSeconds
    )
}

return MenuDisplayModel(
    state: .stale,
    contextName: "Not configured",
    healthSentence: "Cluster status is unavailable",
    primaryStatusReason: failure?.reason ?? "No previous cluster data",
    lastUpdated: "never",
    counters: MenuCounters(nodes: "-", pods: "-", warningEvents: "-"),
    visibleWatchItems: [],
    hiddenWatchItemCount: 0,
    staleBanner: StaleBannerDisplay(lastUpdated: "never", reason: failure?.reason ?? "No previous cluster data")
)
```

Never present stale retained data as OK or current.

### Swift Testing

**Source:** `KubebarTests/Models/MenuDisplayModelTests.swift` lines 1-6

**Apply to:** `MenuStateFixtureCatalogTests.swift`

```swift
import Foundation
import Testing
@testable import KubebarCore

@Suite("Menu display model")
struct MenuDisplayModelTests {
```

Use Swift Testing. Keep focused validation command `swift test --filter MenuStateFixtureCatalogTests`.

### Script Gate

**Source:** `scripts/swift-quality-gate.sh` lines 159-173

**Apply to:** `scripts/generate-qa-evidence.sh`, `scripts/swift-quality-gate.sh`

```bash
main() {
  echo "Swift quality gate mode: $MODE"

  run_xcode_checks

  if [ -f "Package.swift" ]; then
    run_swift_package_checks
    return 0
  fi

  if ! find . -maxdepth 3 \( -name '*.xcworkspace' -o -name '*.xcodeproj' \) | grep -q .; then
    echo "No Xcode workspace/project or Package.swift found." >&2
    return 1
  fi
}
```

Add QA generation as a non-GUI check. Do not require screenshots or menu inspection inside the gate.

### Human Verification Honesty

**Source:** `06-UAT.md` lines 21-30 and `06-VERIFICATION.md` lines 29-32

**Apply to:** `07-UAT.md`, `docs/qa/operator-verification.md`

```markdown
| OK | pending-human-verification | Opened menu shows `OK` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic OK state presentation. |
| Watch | pending-human-verification | Opened menu shows `Watch` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic Watch state reasons. |
| Bad | pending-human-verification | Opened menu shows `Bad` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic Bad state reasons. |
| Stale | pending-human-verification | Opened menu shows `Stale` text, a visible symbol, one short reason, and no color-only meaning. | Requires visible menu inspection. Model tests cover deterministic Stale fallback reasons. |
```

```markdown
Automated and source-level verification passed. The phase cannot be marked `passed` because the visible macOS menu and keyboard traversal remain pending in `06-UAT.md`.
```

If screenshots or real menu traversal cannot complete, mark the exact row `pending-human-verification` or phase status `human_needed`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `docs/assets/qa/` | asset directory | file-I/O | No existing docs screenshot/evidence directory exists. Use simple committed image paths only; do not copy app asset catalog structure. |

## Metadata

**Analog search scope:** `Kubebar/`, `KubebarCore/`, `KubebarTests/`, `scripts/`, `docs/`, `.planning/codebase/`, `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/`, `Package.swift`, `project.yml`

**Files scanned:** 95 files in the analog search scope, plus Phase 07 context/research/validation files.

**Pattern extraction date:** 2026-04-22

