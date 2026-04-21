# Phase 05: Expand kubectl data into actionable warning and workload reasons - Pattern Map

**Mapped:** 2026-04-21
**Files analyzed:** 11 new/modified files
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `KubebarCore/Models/ClusterSnapshot.swift` | model | transform | `KubebarCore/Models/ClusterSnapshot.swift` | exact |
| `KubebarCore/Models/MenuDisplayModel.swift` | model | transform | `KubebarCore/Models/MenuDisplayModel.swift` | exact |
| `KubebarCore/Models/WatchTarget.swift` | model | transform | `KubebarCore/Models/WatchTarget.swift` | exact |
| `KubebarCore/Services/KubectlClusterReader.swift` | service | request-response + transform | `KubebarCore/Services/KubectlClusterReader.swift` | exact |
| `KubebarCore/Services/HealthEvaluator.swift` | service | transform | `KubebarCore/Services/HealthEvaluator.swift` | exact |
| `Kubebar/Views/MenuBarRootView.swift` | component | transform | `Kubebar/Views/MenuBarRootView.swift` | exact |
| `Kubebar/Views/WarningEventsView.swift` | component | transform | `Kubebar/Views/WatchlistSectionView.swift` | role-match |
| `Kubebar/Views/TrackedItemDetailView.swift` | component | transform | `Kubebar/Views/TrackedItemDetailView.swift` | exact |
| `KubebarTests/Services/KubectlClusterReaderTests.swift` | test | request-response + transform | `KubebarTests/Services/KubectlClusterReaderTests.swift` | exact |
| `KubebarTests/Models/MenuDisplayModelTests.swift` | test | transform | `KubebarTests/Models/MenuDisplayModelTests.swift` | exact |
| `KubebarTests/Services/RefreshCoordinatorTests.swift` | test | request-response + transform | `KubebarTests/Services/RefreshCoordinatorTests.swift` | exact |

## Pattern Assignments

### `KubebarCore/Models/ClusterSnapshot.swift` (model, transform)

**Analog:** `KubebarCore/Models/ClusterSnapshot.swift`

**Imports and value-model pattern** (lines 1-21):
```swift
import Foundation

public struct NodeSummary: Equatable, Sendable {
    public let ready: Int
    public let total: Int

    public init(ready: Int, total: Int) {
        self.ready = ready
        self.total = total
    }
}
```

**Snapshot construction pattern** (lines 23-45):
```swift
public struct ClusterSnapshot: Equatable, Sendable {
    public let contextName: String
    public let nodeSummary: NodeSummary
    public let podSummary: PodSummary
    public let warningEventCount: Int
    public let trackedItems: [TrackedItemStatus]
    public let capturedAt: Date

    public init(
        contextName: String,
        nodeSummary: NodeSummary,
        podSummary: PodSummary,
        warningEventCount: Int,
        trackedItems: [TrackedItemStatus],
        capturedAt: Date
    ) {
        self.contextName = contextName
        self.nodeSummary = nodeSummary
        self.podSummary = podSummary
        self.warningEventCount = warningEventCount
        self.trackedItems = trackedItems
        self.capturedAt = capturedAt
    }
}
```

**Copy pattern:** add new public value types here with `Equatable, Sendable`, immutable `let` properties, and explicit public initializers. For section-aware reads, use the research shape from `05-RESEARCH.md` lines 282-296:
```swift
enum SnapshotSection<Value: Equatable & Sendable>: Equatable, Sendable {
    case available(Value)
    case unavailable(reason: String)
}
```

Apply section state to node, pod, warning event, and tracked-item facts without exposing raw `kubectl` JSON.

---

### `KubebarCore/Models/MenuDisplayModel.swift` (model, transform)

**Analog:** `KubebarCore/Models/MenuDisplayModel.swift`

**Display-model field pattern** (lines 3-19):
```swift
public struct MenuCounters: Equatable, Sendable {
    public let nodes: String
    public let pods: String
    public let warningEvents: String
}

public struct WatchItemDisplay: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let state: ClusterHealthState
    public let reason: String
}
```

**Menu render contract pattern** (lines 21-47):
```swift
public struct MenuDisplayModel: Equatable, Sendable {
    public let state: ClusterHealthState
    public let contextName: String
    public let healthSentence: String
    public let counters: MenuCounters
    public let visibleWatchItems: [WatchItemDisplay]
    public let hiddenWatchItemCount: Int
    public let staleBanner: StaleBannerDisplay?

    public init(
        state: ClusterHealthState,
        contextName: String,
        healthSentence: String,
        counters: MenuCounters,
        visibleWatchItems: [WatchItemDisplay],
        hiddenWatchItemCount: Int,
        staleBanner: StaleBannerDisplay?
    ) {
        self.state = state
        self.contextName = contextName
        self.healthSentence = healthSentence
        self.counters = counters
        self.visibleWatchItems = visibleWatchItems
        self.hiddenWatchItemCount = hiddenWatchItemCount
        self.staleBanner = staleBanner
    }
}
```

**Copy pattern:** keep `MenuCounters.warningEvents` as the compact count. Add display-ready warning summaries and tracked detail values here, not in SwiftUI. Use the research detail model from `05-RESEARCH.md` lines 322-339 as the shape:
```swift
struct WatchItemDetailDisplay: Equatable, Sendable {
    let stateLabel: String
    let reason: String
    let affectedPodCount: Int?
    let examplePodNames: [String]
    let latestWarning: WarningEventDisplay?
}
```

---

### `KubebarCore/Models/WatchTarget.swift` (model, transform)

**Analog:** `KubebarCore/Models/WatchTarget.swift`

**Durable target enum pattern** (lines 3-14):
```swift
public enum WatchTarget: Codable, Equatable, Hashable, Sendable {
    case namespace(String)
    case workload(namespace: String, name: String, kind: WorkloadKind = .deployment)

    public var displayTitle: String {
        switch self {
        case let .namespace(name):
            name
        case let .workload(namespace, name, _):
            "\(namespace)/\(name)"
        }
    }
}
```

**Runtime status pattern** (lines 63-73):
```swift
public struct TrackedItemStatus: Equatable, Sendable {
    public let target: WatchTarget
    public let state: ClusterHealthState
    public let reason: String

    public init(target: WatchTarget, state: ClusterHealthState, reason: String) {
        self.target = target
        self.state = state
        self.reason = reason
    }
}
```

**Workload kind support pattern:** `KubebarCore/Models/WorkloadKind.swift` lines 3-34 already maps supported kinds to display names and kubectl resources:
```swift
public enum WorkloadKind: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case deployment
    case statefulSet
    case daemonSet
    case cronJob

    public var kubectlResource: String {
        switch self {
        case .deployment:
            "deployments"
        case .statefulSet:
            "statefulsets"
        case .daemonSet:
            "daemonsets"
        case .cronJob:
            "cronjobs"
        }
    }
}
```

**Copy pattern:** keep `WatchTarget` durable and small. Add runtime-only reason/detail data to `TrackedItemStatus` or a nearby runtime model, not to Codable setup state unless it must persist.

---

### `KubebarCore/Services/KubectlClusterReader.swift` (service, request-response + transform)

**Analog:** `KubebarCore/Services/KubectlClusterReader.swift`

**Imports, protocol, injection pattern** (lines 1-12):
```swift
import Foundation

public protocol ClusterReading: Sendable {
    func readSnapshot(contextName: String, watchTargets: [WatchTarget], now: Date) throws -> ClusterSnapshot
}

public struct KubectlClusterReader: ClusterReading, Sendable {
    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }
}
```

**Read and app-owned context pattern** (lines 14-28):
```swift
public func readSnapshot(contextName: String, watchTargets: [WatchTarget], now: Date) throws -> ClusterSnapshot {
    let rawSnapshot = try readRawSnapshot(contextName: contextName)
    let nodes = try decodeNodes(rawSnapshot.nodes)
    let pods = try decodePods(rawSnapshot.pods)
    let warningEventCount = try decodeEventCount(rawSnapshot.warningEvents)

    return ClusterSnapshot(
        contextName: contextName,
        nodeSummary: nodes,
        podSummary: PodSummary(running: pods.filter(\.isRunning).count, total: pods.count),
        warningEventCount: warningEventCount,
        trackedItems: watchTargets.map { target in trackedStatus(for: target, pods: pods) },
        capturedAt: now
    )
}
```

**Concurrent kubectl read pattern** (lines 30-66):
```swift
private func readRawSnapshot(contextName: String) throws -> RawKubectlSnapshot {
    let results = LockedKubectlResults()
    let group = DispatchGroup()

    for read in KubectlRead.allCases {
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let output = try runKubectl(contextName: contextName, arguments: read.arguments)
                results.set(.success(output), for: read)
            } catch let error as KubectlCommandError {
                results.set(.failure(error), for: read)
            } catch {
                results.set(.failure(.failed(error.localizedDescription)), for: read)
            }
            group.leave()
        }
    }

    group.wait()
```

**Command error pattern** (lines 68-86):
```swift
private func runKubectl(contextName: String, arguments: [String]) throws -> String {
    let result: CommandResult
    do {
        result = try runner.run(
            CommandRequest(executable: "kubectl", arguments: ["--context", contextName] + arguments)
        )
    } catch CommandRunnerError.timedOut {
        throw KubectlCommandError.failed("kubectl timed out")
    } catch CommandRunnerError.launchFailed {
        throw KubectlCommandError.failed("kubectl could not be launched")
    }

    guard result.exitCode == 0 else {
        let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        throw KubectlCommandError.failed(message.isEmpty ? "kubectl failed" : message)
    }

    return result.stdout
}
```

**Structured JSON decode pattern** (lines 88-112):
```swift
private func decodeNodes(_ json: String) throws -> NodeSummary {
    do {
        let nodeList = try JSONDecoder().decode(NodeList.self, from: Data(json.utf8))
        let ready = nodeList.items.filter(\.isReady).count
        return NodeSummary(ready: ready, total: nodeList.items.count)
    } catch {
        throw KubectlCommandError.failed("invalid node JSON")
    }
}

private func decodePods(_ json: String) throws -> [PodRecord] {
    do {
        return try JSONDecoder().decode(PodList.self, from: Data(json.utf8)).items
    } catch {
        throw KubectlCommandError.failed("invalid pod JSON")
    }
}
```

**Tracked status pattern to replace with richer classifier** (lines 114-135):
```swift
private func trackedStatus(for target: WatchTarget, pods: [PodRecord]) -> TrackedItemStatus {
    let matchingPods = pods.filter { pod in
        switch target {
        case let .namespace(namespace):
            pod.metadata.namespace == namespace
        case let .workload(namespace, name, _):
            pod.metadata.namespace == namespace && pod.matchesWorkload(named: name)
        }
    }

    guard !matchingPods.isEmpty else {
        return TrackedItemStatus(target: target, state: .bad, reason: "no matching pods")
    }
```

**Existing private record pattern** (lines 199-226):
```swift
private struct PodList: Decodable {
    let items: [PodRecord]
}

private struct PodRecord: Decodable {
    struct Metadata: Decodable {
        let namespace: String
        let name: String
        let labels: [String: String]?
    }

    struct Status: Decodable {
        let phase: String
    }

    let metadata: Metadata
    let status: Status
}
```

**Workload catalog analog for kind loops:** `KubebarCore/Services/WatchTargetCatalog.swift` lines 17-35:
```swift
return try await withThrowingTaskGroup(of: DiscoveryResult.self) { group in
    group.addTask {
        try Task.checkCancellation()
        let json = try runKubectl(contextName: contextName, arguments: ["get", "namespaces", "-o", "json"])
        try Task.checkCancellation()
        return .namespaces(try decodeNamespaces(json))
    }

    for kind in WorkloadKind.allCases {
        group.addTask {
            try Task.checkCancellation()
            let json = try runKubectl(
                contextName: contextName,
                arguments: ["get", kind.kubectlResource, "--all-namespaces", "-o", "json"]
            )
```

**Copy pattern:** keep using `CommandRunning`, argument arrays, `--context`, `-o json`, private `Decodable` records, and product-specific parse errors. For Phase 05, change all-or-nothing `try result.get()` behavior into section-aware results so malformed event JSON can mark only the events section unavailable.

---

### `KubebarCore/Services/HealthEvaluator.swift` (service, transform)

**Analog:** `KubebarCore/Services/HealthEvaluator.swift`

**Public deterministic evaluator pattern** (lines 18-41):
```swift
public func evaluate(
    snapshot: ClusterSnapshot?,
    previousSnapshot: ClusterSnapshot? = nil,
    failure: RefreshFailure? = nil,
    now: Date
) -> MenuDisplayModel {
    if let snapshot {
        return displayModel(from: snapshot, stateOverride: nil, failure: failure, now: now)
    }

    if let previousSnapshot {
        return displayModel(from: previousSnapshot, stateOverride: .stale, failure: failure, now: now)
    }

    return MenuDisplayModel(
        state: .stale,
        contextName: "Not configured",
        healthSentence: "Cluster status is unavailable",
        counters: MenuCounters(nodes: "-", pods: "-", warningEvents: "-"),
        visibleWatchItems: [],
        hiddenWatchItemCount: 0,
        staleBanner: StaleBannerDisplay(lastUpdated: "never", reason: failure?.reason ?? "No cluster data")
    )
}
```

**Display construction pattern** (lines 43-67):
```swift
private func displayModel(
    from snapshot: ClusterSnapshot,
    stateOverride: ClusterHealthState?,
    failure: RefreshFailure?,
    now: Date
) -> MenuDisplayModel {
    let sortedItems = sortByAttention(snapshot.trackedItems)
    let visibleItems = sortedItems.prefix(visibleWatchItemLimit).map(makeDisplayItem)
    let hiddenCount = max(0, sortedItems.count - visibleItems.count)
    let resolvedState = stateOverride ?? evaluateState(snapshot)

    return MenuDisplayModel(
        state: resolvedState,
        contextName: snapshot.contextName,
        healthSentence: healthSentence(for: resolvedState, visibleItems: visibleItems),
        counters: MenuCounters(
            nodes: "\(snapshot.nodeSummary.ready)/\(snapshot.nodeSummary.total)",
            pods: "\(snapshot.podSummary.running)/\(snapshot.podSummary.total)",
            warningEvents: "\(snapshot.warningEventCount)"
        ),
```

**Severity and attention ordering pattern** (lines 69-91):
```swift
private func evaluateState(_ snapshot: ClusterSnapshot) -> ClusterHealthState {
    if snapshot.nodeSummary.ready < snapshot.nodeSummary.total || snapshot.trackedItems.contains(where: { $0.state == .bad }) {
        return .bad
    }

    if snapshot.podSummary.running < snapshot.podSummary.total ||
        snapshot.warningEventCount > 0 ||
        snapshot.trackedItems.contains(where: { $0.state == .watch }) {
        return .watch
    }

    return .ok
}

private func sortByAttention(_ items: [TrackedItemStatus]) -> [TrackedItemStatus] {
    items.sorted { left, right in
        if left.state.rawValue != right.state.rawValue {
            return left.state.rawValue > right.state.rawValue
        }

        return left.target.displayTitle < right.target.displayTitle
    }
}
```

**Display item and stale pattern** (lines 93-128):
```swift
private func makeDisplayItem(_ item: TrackedItemStatus) -> WatchItemDisplay {
    WatchItemDisplay(
        id: item.target.displayTitle,
        title: shortened(item.target.displayTitle),
        state: item.state,
        reason: item.reason
    )
}

private func staleBanner(
    for state: ClusterHealthState,
    snapshot: ClusterSnapshot,
    failure: RefreshFailure?,
    now: Date
) -> StaleBannerDisplay? {
    guard state == .stale else {
        return nil
    }
```

**Copy pattern:** keep reason priority and warning grouping here. Apply locked priority `missing/failed > restarting > pending/unready > warning`, cap warning summaries at 3, and cap detail examples at 1-3 before SwiftUI receives them.

---

### `Kubebar/Views/MenuBarRootView.swift` (component, transform)

**Analog:** `Kubebar/Views/MenuBarRootView.swift`

**Composition root pattern** (lines 36-49):
```swift
private var menuContent: some View {
    VStack(alignment: .leading, spacing: 14) {
        StatusSummaryView(display: display)
        StaleBannerView(banner: display.staleBanner)
        CompactCountersView(counters: display.counters)
        WatchlistSectionView(display: display)
        WarningEventsView(count: display.counters.warningEvents)
        NodeDetailsView(summary: display.counters.nodes)
        Divider()
        refreshControls
        actions
    }
    .frame(width: 340)
    .padding(16)
}
```

**Copy pattern:** keep root view as wiring only. After `MenuDisplayModel` exposes warning summaries, pass prepared display fields into `WarningEventsView`; do not parse event state in this file.

---

### `Kubebar/Views/WarningEventsView.swift` (component, transform)

**Primary analog:** `Kubebar/Views/WatchlistSectionView.swift`

**Existing warning view pattern** (lines 3-15):
```swift
struct WarningEventsView: View {
    let count: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Warning events")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(count == "0" ? "No current warning events" : "\(count) warning events need review")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

**List rendering analog:** `Kubebar/Views/WatchlistSectionView.swift` lines 13-31:
```swift
if display.visibleWatchItems.isEmpty {
    Text("No tracked workloads yet")
        .font(.subheadline)
        .foregroundStyle(.secondary)
} else {
    ForEach(display.visibleWatchItems) { item in
        DisclosureGroup {
            TrackedItemDetailView(item: item)
        } label: {
            WatchlistRowView(item: item)
        }
    }
}

if display.hiddenWatchItemCount > 0 {
    Text("View all tracked (\(display.hiddenWatchItemCount) more)")
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

**Compact label analog:** `Kubebar/Views/NodeDetailsView.swift` lines 7-15:
```swift
VStack(alignment: .leading, spacing: 4) {
    Text("Node details")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

    Text("\(summary) nodes ready")
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

**Copy pattern:** render an empty state plus up to 3 prepared summary rows from `MenuDisplayModel`. Use `ForEach` only over display-ready `Identifiable` rows. Keep messages shortened before they reach this view.

---

### `Kubebar/Views/TrackedItemDetailView.swift` (component, transform)

**Analog:** `Kubebar/Views/TrackedItemDetailView.swift`

**Imports and detail rendering pattern** (lines 1-15):
```swift
import SwiftUI
import KubebarCore

struct TrackedItemDetailView: View {
    let item: WatchItemDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("State: \(item.state.label)")
            Text(item.reason)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.leading, 6)
    }
}
```

**Parent disclosure analog:** `Kubebar/Views/WatchlistSectionView.swift` lines 18-23:
```swift
ForEach(display.visibleWatchItems) { item in
    DisclosureGroup {
        TrackedItemDetailView(item: item)
    } label: {
        WatchlistRowView(item: item)
    }
}
```

**Copy pattern:** keep detail confirmatory and short. Render prepared fields from `WatchItemDisplay` or a nested detail display object: state, reason, affected pod count, 1-3 example pod names, and latest related warning. Do not show raw pod JSON, raw event JSON, full event body, or shell handoff actions.

---

### `KubebarTests/Services/KubectlClusterReaderTests.swift` (test, request-response + transform)

**Analog:** `KubebarTests/Services/KubectlClusterReaderTests.swift`

**Test imports and suite pattern** (lines 1-8):
```swift
import Foundation
import Testing
@testable import KubebarCore

@Suite("Kubectl cluster reader")
struct KubectlClusterReaderTests {
    @Test("builds a cluster snapshot from kubectl JSON")
    func buildsClusterSnapshotFromKubectlJSON() throws {
```

**Fixture-driven reader test pattern** (lines 9-28):
```swift
let runner = FakeMultiCommandRunner(results: [
    ["--context", "prod", "get", "nodes", "-o", "json"]: CommandResult(stdout: nodesJSON, stderr: "", exitCode: 0),
    ["--context", "prod", "get", "pods", "--all-namespaces", "-o", "json"]: CommandResult(stdout: podsJSON, stderr: "", exitCode: 0),
    ["--context", "prod", "get", "events", "--all-namespaces", "--field-selector", "type=Warning", "-o", "json"]: CommandResult(stdout: warningEventsJSON, stderr: "", exitCode: 0)
])
let reader = KubectlClusterReader(runner: runner)

let snapshot = try reader.readSnapshot(
    contextName: "prod",
    watchTargets: [.workload(namespace: "api", name: "checkout")],
    now: Date(timeIntervalSince1970: 100)
)

#expect(snapshot.contextName == "prod")
#expect(snapshot.nodeSummary == NodeSummary(ready: 1, total: 2))
#expect(snapshot.podSummary == PodSummary(running: 1, total: 3))
#expect(snapshot.warningEventCount == 1)
#expect(snapshot.trackedItems.first?.state == .bad)
#expect(snapshot.trackedItems.first?.reason == "1/2 pods running")
```

**Fake command runner pattern** (lines 61-70):
```swift
private final class FakeMultiCommandRunner: CommandRunning, @unchecked Sendable {
    private let results: [[String]: CommandResult]

    init(results: [[String]: CommandResult]) {
        self.results = results
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        results[request.arguments] ?? CommandResult(stdout: "", stderr: "unexpected command", exitCode: 1)
    }
}
```

**Concurrency fake pattern** (lines 73-109):
```swift
private final class SlowRecordingCommandRunner: CommandRunning, @unchecked Sendable {
    private let results: [[String]: CommandResult]
    private let lock = NSLock()
    private var activeRequests = 0
    private var observedMaximumConcurrentRequests = 0

    init(results: [[String]: CommandResult]) {
        self.results = results
    }
```

**Inline JSON fixture pattern** (lines 111-136):
```swift
private let nodesJSON = """
{
  "items": [
    {"status": {"conditions": [{"type": "Ready", "status": "True"}]}},
    {"status": {"conditions": [{"type": "Ready", "status": "False"}]}}
  ]
}
"""

private let warningEventsJSON = """
{
  "items": [
    {"metadata": {"namespace": "api", "name": "checkout-warning"}}
  ]
}
"""
```

**Copy pattern:** add cases for empty event list, malformed event JSON, partial node/pod/event failures, core/v1 event shape, events.k8s.io/v1 event shape, pending, running-but-unready, restarting, failed, and missing pods. Keep all fixtures private and local to the test file.

---

### `KubebarTests/Models/MenuDisplayModelTests.swift` (test, transform)

**Analog:** `KubebarTests/Models/MenuDisplayModelTests.swift`

**Display model test pattern** (lines 7-28):
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

    #expect(display.state == .ok)
    #expect(display.contextName == "prod")
    #expect(display.counters.nodes == "3/3")
    #expect(display.counters.pods == "12/12")
    #expect(display.counters.warningEvents == "0")
    #expect(display.healthSentence == "Cluster looks healthy")
}
```

**Attention ordering pattern** (lines 30-50):
```swift
@Test("bad tracked items become first-screen attention")
func badTrackedItemsBecomeFirstScreenAttention() {
    let snapshot = ClusterSnapshot(
        contextName: "prod",
        nodeSummary: NodeSummary(ready: 3, total: 3),
        podSummary: PodSummary(running: 5, total: 6),
        warningEventCount: 1,
        trackedItems: [
            TrackedItemStatus(target: .workload(namespace: "api", name: "checkout"), state: .bad, reason: "1 pod pending"),
            TrackedItemStatus(target: .namespace("monitoring"), state: .ok, reason: "all watched pods running")
        ],
        capturedAt: Date(timeIntervalSince1970: 100)
    )

    let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

    #expect(display.state == .bad)
    #expect(display.visibleWatchItems.first?.title == "api/checkout")
    #expect(display.visibleWatchItems.first?.reason == "1 pod pending")
    #expect(display.healthSentence == "api/checkout needs attention")
}
```

**Cap behavior pattern** (lines 52-70):
```swift
@Test("first screen caps watchlist and reports overflow")
func firstScreenCapsWatchlistAndReportsOverflow() {
    let items = (1...7).map { index in
        TrackedItemStatus(target: .workload(namespace: "team", name: "service-\(index)"), state: .ok, reason: "ready")
    }
    let snapshot = ClusterSnapshot(
        contextName: "prod",
        nodeSummary: NodeSummary(ready: 3, total: 3),
        podSummary: PodSummary(running: 20, total: 20),
        warningEventCount: 0,
        trackedItems: items,
        capturedAt: Date(timeIntervalSince1970: 100)
    )

    let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

    #expect(display.visibleWatchItems.count == 5)
    #expect(display.hiddenWatchItemCount == 2)
}
```

**Stale reason preservation pattern** (lines 94-119):
```swift
@Test("failed refresh keeps previous data but marks it stale")
func failedRefreshKeepsPreviousDataButMarksItStale() {
    let previous = ClusterSnapshot(
        contextName: "prod",
        nodeSummary: NodeSummary(ready: 3, total: 3),
        podSummary: PodSummary(running: 12, total: 12),
        warningEventCount: 0,
        trackedItems: [
            TrackedItemStatus(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "6/6 pods running")
        ],
        capturedAt: Date(timeIntervalSince1970: 100)
    )

    let display = HealthEvaluator().evaluate(
        snapshot: nil,
        previousSnapshot: previous,
        failure: RefreshFailure(reason: "kubectl timed out"),
        now: Date(timeIntervalSince1970: 250)
    )

    #expect(display.state == .stale)
    #expect(display.contextName == "prod")
    #expect(display.staleBanner?.lastUpdated == "2m ago")
    #expect(display.staleBanner?.reason == "kubectl timed out")
    #expect(display.visibleWatchItems.first?.title == "api/checkout")
}
```

**Copy pattern:** add mapping tests for warning summary cap, duplicate event grouping, section-unavailable display, detail cap, reason priority, and stale display preserving known row reasons.

---

### `KubebarTests/Services/RefreshCoordinatorTests.swift` (test, request-response + transform)

**Analog:** `KubebarTests/Services/RefreshCoordinatorTests.swift`

**Stale fallback test pattern** (lines 29-51):
```swift
@Test("failed refresh keeps previous snapshot as stale display")
func failedRefreshKeepsPreviousSnapshotAsStaleDisplay() {
    let previous = ClusterSnapshot(
        contextName: "prod",
        nodeSummary: NodeSummary(ready: 1, total: 1),
        podSummary: PodSummary(running: 1, total: 1),
        warningEventCount: 0,
        trackedItems: [.init(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "1/1 pods running")],
        capturedAt: Date(timeIntervalSince1970: 100)
    )
    let coordinator = RefreshCoordinator(reader: FakeClusterReader(result: .failure(KubectlCommandError.failed("cluster unreachable"))))

    let result = coordinator.refresh(
        config: AppConfig(selectedContext: "prod", watchTargets: [.workload(namespace: "api", name: "checkout")]),
        previousSnapshot: previous,
        now: Date(timeIntervalSince1970: 220)
    )

    #expect(result.snapshot == previous)
    #expect(result.display.state == .stale)
    #expect(result.display.staleBanner?.reason == "cluster unreachable")
    #expect(result.display.staleBanner?.lastUpdated == "2m ago")
}
```

**Fake reader pattern** (lines 65-70):
```swift
private struct FakeClusterReader: ClusterReading {
    let result: Result<ClusterSnapshot, Error>

    func readSnapshot(contextName: String, watchTargets: [WatchTarget], now: Date) throws -> ClusterSnapshot {
        try result.get()
    }
}
```

**Copy pattern:** use this file only if the planner changes how partial section failures interact with global stale fallback. Preserve the existing guarantee that whole-refresh failures keep the previous snapshot and render stale with the known failure reason.

## Shared Patterns

### Architecture Boundary

**Source:** `.planning/codebase/ARCHITECTURE.md` lines 7-15, 42-56, 74-80
**Apply to:** all Phase 05 files

- SwiftUI views render `MenuDisplayModel`; they must not infer cluster health from raw data.
- Core models under `KubebarCore/Models/` are value types with `Foundation` only.
- Core services under `KubebarCore/Services/` own external reads, JSON conversion, health evaluation, and display construction.
- `HealthEvaluator` is the owner for severity, watchlist ordering, visible item limits, stale banner values, and health sentences.

### External Command Boundary

**Source:** `KubebarCore/Services/CommandRunner.swift` lines 3-29 and `KubebarCore/Services/KubectlClusterReader.swift` lines 68-86
**Apply to:** `KubebarCore/Services/KubectlClusterReader.swift`

```swift
public struct CommandRequest: Equatable, Sendable {
    public let executable: String
    public let arguments: [String]
    public let timeoutSeconds: TimeInterval
}

public protocol CommandRunning: Sendable {
    func run(_ request: CommandRequest) throws -> CommandResult
}
```

Keep every new `kubectl` read behind `CommandRunning`; use argument arrays and include `["--context", contextName]`.

### Error Handling

**Source:** `.planning/codebase/CONVENTIONS.md` lines 52-60; `KubebarCore/Services/KubectlClusterReader.swift` lines 88-112
**Apply to:** reader, evaluator, tests

- Convert malformed JSON into product-specific `KubectlCommandError.failed("invalid ... JSON")`.
- For Phase 05 partial reads, do not silently hide failures. Represent failed sections as unavailable/stale in model/display state.
- Keep raw stdout and full JSON out of display models.

### UI Rendering

**Source:** `Kubebar/Views/WatchlistSectionView.swift` lines 7-32; `Kubebar/Views/TrackedItemDetailView.swift` lines 7-15
**Apply to:** `WarningEventsView`, `TrackedItemDetailView`, `MenuBarRootView`

```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Watchlist")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

    if display.visibleWatchItems.isEmpty {
        Text("No tracked workloads yet")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    } else {
        ForEach(display.visibleWatchItems) { item in
            DisclosureGroup {
                TrackedItemDetailView(item: item)
            } label: {
                WatchlistRowView(item: item)
            }
        }
    }
}
```

Render short display-ready values. Do not add raw event timelines, raw pod dumps, `Open in k9s`, dashboard pages, or deeper troubleshooting UI.

### Test Fixtures

**Source:** `.planning/codebase/TESTING.md` lines 47-75, 120-153; `KubebarTests/Services/KubectlClusterReaderTests.swift` lines 61-136
**Apply to:** both test files

- Use Swift Testing with `@Suite`, `@Test`, and `#expect`.
- Keep fake command runners private and local to the service test file.
- Keep JSON fixtures as private inline multiline strings in the test file.
- Use deterministic `Date(timeIntervalSince1970:)` values for age and stale assertions.

## No Analog Found

All planned files have a close existing analog. The only new concept without an exact current code analog is section-aware partial snapshot state; use the research pattern in `05-RESEARCH.md` lines 282-296 and keep it inside `ClusterSnapshot` / `HealthEvaluator`.

## Scope Guards

- Do not add full dashboard screens.
- Do not add shell handoff or `Open in k9s`.
- Do not read Kubernetes Secrets.
- Do not show raw `kubectl` event or pod output in the menu.
- Do not change distribution, packaging, notarization, or AppKit `NSStatusItem` behavior.
- Preserve watchlist-first ordering and the 3-5 first-screen row cap.

## Metadata

**Analog search scope:** `KubebarCore/Models`, `KubebarCore/Services`, `Kubebar/Views`, `KubebarTests/Models`, `KubebarTests/Services`
**Files scanned:** 44 Swift files plus phase/codebase planning docs
**Pattern extraction date:** 2026-04-21
**Validation commands for planner:** focused `swift test --filter KubectlClusterReaderTests`, focused `swift test --filter MenuDisplayModelTests`, then `./scripts/swift-quality-gate.sh local`
