import Foundation
import Testing
@testable import KubebarCore

@Suite("Kubectl cluster reader")
struct KubectlClusterReaderTests {
    @Test("builds a cluster snapshot from kubectl JSON")
    func buildsClusterSnapshotFromKubectlJSON() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: warningEventsJSON, error: "", exitCode: 0)
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
    }

    @Test("legacy snapshot initializer preserves warning count and available sections")
    func legacySnapshotInitializerPreservesWarningCountAndAvailableSections() throws {
        let trackedItem = TrackedItemStatus(
            target: .workload(namespace: "api", name: "checkout"),
            state: .watch,
            reason: "latest warning: BackOff",
            affectedPodCount: 1,
            examplePodNames: ["checkout-7f9d"],
            latestWarning: WarningEventRecord(
                reason: "BackOff",
                namespace: "api",
                objectKind: "Pod",
                objectName: "checkout-7f9d",
                message: "Back-off restarting failed container",
                observedAt: Date(timeIntervalSince1970: 90),
                count: 2
            )
        )
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 1, total: 1),
            podSummary: PodSummary(running: 1, total: 1),
            warningEventCount: 1,
            trackedItems: [trackedItem],
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        #expect(snapshot.warningEventCount == 1)
        #expect(snapshot.nodesSection.value == NodeSummary(ready: 1, total: 1))
        #expect(snapshot.podsSection.value == PodSummary(running: 1, total: 1))
        #expect(snapshot.warningEventsSection.value == [])
        #expect(snapshot.workloadsSection.value == [trackedItem])
        #expect(snapshot.sectionFailures == [])
    }

    @Test("kubectl command failure reports stderr")
    func kubectlCommandFailureReportsStderr() {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: "", error: "cluster unreachable", exitCode: 1)
        ])
        let reader = KubectlClusterReader(runner: runner)

        #expect(throws: KubectlCommandError.failed("cluster unreachable")) {
            try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date())
        }
    }

    @Test("empty warning event list is available")
    func emptyWarningEventListIsAvailable() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))

        #expect(snapshot.warningEventCount == 0)
        #expect(snapshot.warningEventsSection.isAvailable == true)
        #expect(snapshot.warningEventsSection.value == [])
        #expect(!snapshot.sectionFailures.contains { $0.section == .warningEvents })
    }

    @Test("malformed warning event JSON only marks warning events unavailable")
    func malformedWarningEventJSONOnlyMarksWarningEventsUnavailable() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: "{", error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))

        #expect(snapshot.nodesSection.isAvailable == true)
        #expect(snapshot.podsSection.isAvailable == true)
        #expect(snapshot.warningEventsSection.unavailableReason == "invalid event JSON")
        #expect(snapshot.sectionFailures.contains(SnapshotSectionFailure(section: .warningEvents, reason: "invalid event JSON")))
    }

    @Test("Legacy core Event fixture decodes warning event details")
    func legacyCoreEventFixtureDecodesWarningEventDetails() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: legacyCoreEventJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))
        let event = try #require(snapshot.warningEventsSection.value?.first)

        #expect(event.reason == "BackOff")
        #expect(event.namespace == "api")
        #expect(event.objectKind == "Pod")
        #expect(event.objectName == "checkout-7f9d")
        #expect(event.message == "Back-off restarting failed container")
        #expect(event.observedAt == Date(timeIntervalSince1970: 1_713_783_600))
        #expect(event.count == 3)
        #expect(snapshot.warningEventCount == 3)
    }

    @Test("events.k8s.io Event fixture decodes warning event details")
    func eventsAPIEventFixtureDecodesWarningEventDetails() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: eventsAPIEventJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))
        let event = try #require(snapshot.warningEventsSection.value?.first)

        #expect(event.reason == "FailedScheduling")
        #expect(event.namespace == "api")
        #expect(event.objectKind == "Pod")
        #expect(event.objectName == "checkout-8a1b")
        #expect(event.message == "0/3 nodes are available")
        #expect(event.observedAt == Date(timeIntervalSince1970: 1_713_787_200))
        #expect(event.count == 4)
        #expect(snapshot.warningEventCount == 4)
    }

    @Test("warning event failure reasons redact paths and token text")
    func warningEventFailureReasonsRedactPathsAndTokenText() throws {
        let pathRunner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: "", error: "open /Users/example/.kube/config: permission denied", exitCode: 1)
        ])
        let tokenRunner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: "", error: "token expired for cluster", exitCode: 1)
        ])

        let pathSnapshot = try KubectlClusterReader(runner: pathRunner)
            .readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))
        let tokenSnapshot = try KubectlClusterReader(runner: tokenRunner)
            .readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))

        #expect(pathSnapshot.warningEventsSection.unavailableReason == "open ~/.kube/config: permission denied")
        #expect(tokenSnapshot.warningEventsSection.unavailableReason == "kubectl failed")
    }

    @Test("reader never asks for Kubernetes secrets")
    func readerNeverAsksForKubernetesSecrets() throws {
        let runner = RecordingCommandRunner(result: CommandResult(output: emptyListJSON, error: "", exitCode: 0))
        let reader = KubectlClusterReader(runner: runner)

        _ = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))

        #expect(!runner.requests.contains { $0.arguments.contains("secrets") })
    }

    @Test("reads independent kubectl resources concurrently")
    func readsIndependentKubectlResourcesConcurrently() throws {
        let runner = SlowRecordingCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: warningEventsJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        _ = try reader.readSnapshot(
            contextName: "prod",
            watchTargets: [.workload(namespace: "api", name: "checkout")],
            now: Date(timeIntervalSince1970: 100)
        )

        #expect(runner.maximumConcurrentRequests > 1)
    }
}

private final class FakeMultiCommandRunner: CommandRunning, @unchecked Sendable {
    private let results: [[String]: CommandResult]

    init(results: [[String]: CommandResult]) {
        self.results = results
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        results[request.arguments] ?? CommandResult(output: "", error: "unexpected command", exitCode: 1)
    }
}

private final class RecordingCommandRunner: CommandRunning, @unchecked Sendable {
    private let result: CommandResult
    private let lock = NSLock()
    private var recordedRequests: [CommandRequest] = []

    init(result: CommandResult) {
        self.result = result
    }

    var requests: [CommandRequest] {
        lock.lock()
        defer { lock.unlock() }
        return recordedRequests
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        lock.lock()
        recordedRequests.append(request)
        lock.unlock()
        return result
    }
}

private final class SlowRecordingCommandRunner: CommandRunning, @unchecked Sendable {
    private let results: [[String]: CommandResult]
    private let lock = NSLock()
    private var activeRequests = 0
    private var observedMaximumConcurrentRequests = 0

    init(results: [[String]: CommandResult]) {
        self.results = results
    }

    var maximumConcurrentRequests: Int {
        lock.lock()
        defer { lock.unlock() }
        return observedMaximumConcurrentRequests
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        incrementActiveRequests()
        Thread.sleep(forTimeInterval: 0.05)
        decrementActiveRequests()

        return results[request.arguments] ?? CommandResult(output: "", error: "unexpected command", exitCode: 1)
    }

    private func incrementActiveRequests() {
        lock.lock()
        activeRequests += 1
        observedMaximumConcurrentRequests = max(observedMaximumConcurrentRequests, activeRequests)
        lock.unlock()
    }

    private func decrementActiveRequests() {
        lock.lock()
        activeRequests -= 1
        lock.unlock()
    }
}

private let nodesCommand = ["--context", "prod", "get", "nodes", "-o", "json"]
private let podsCommand = ["--context", "prod", "get", "pods", "--all-namespaces", "-o", "json"]
private let warningEventsCommand = ["--context", "prod", "get", "events", "--all-namespaces", "--field-selector", "type=Warning", "-o", "json"]

private let nodesJSON = """
{
  "items": [
    {"status": {"conditions": [{"type": "Ready", "status": "True"}]}},
    {"status": {"conditions": [{"type": "Ready", "status": "False"}]}}
  ]
}
"""

private let podsJSON = """
{
  "items": [
    {"metadata": {"namespace": "api", "name": "checkout-7f9d", "labels": {"app.kubernetes.io/name": "checkout"}}, "status": {"phase": "Running"}},
    {"metadata": {"namespace": "api", "name": "checkout-8a1b", "labels": {"app.kubernetes.io/name": "checkout"}}, "status": {"phase": "Pending"}},
    {"metadata": {"namespace": "api", "name": "checkout-worker-1", "labels": {"app.kubernetes.io/name": "checkout-worker"}}, "status": {"phase": "Pending"}}
  ]
}
"""

private let emptyListJSON = """
{
  "items": []
}
"""

private let warningEventsJSON = """
{
  "items": [
    {"metadata": {"namespace": "api", "name": "checkout-warning"}}
  ]
}
"""

private let legacyCoreEventJSON = """
{
  "items": [
    {
      "metadata": {
        "namespace": "api",
        "creationTimestamp": "2024-04-18T09:00:00Z"
      },
      "reason": "BackOff",
      "message": "Back-off restarting failed container",
      "involvedObject": {
        "kind": "Pod",
        "namespace": "api",
        "name": "checkout-7f9d"
      },
      "lastTimestamp": "2024-04-18T10:00:00Z",
      "eventTime": "2024-04-18T09:55:00Z",
      "count": 3
    }
  ]
}
"""

private let eventsAPIEventJSON = """
{
  "items": [
    {
      "metadata": {
        "namespace": "api",
        "creationTimestamp": "2024-04-18T09:00:00Z"
      },
      "reason": "FailedScheduling",
      "note": "0/3 nodes are available",
      "regarding": {
        "kind": "Pod",
        "namespace": "api",
        "name": "checkout-8a1b"
      },
      "eventTime": "2024-04-18T11:30:00Z",
      "series": {
        "lastObservedTime": "2024-04-18T11:00:00Z",
        "count": 4
      },
      "deprecatedCount": 2,
      "deprecatedLastTimestamp": "2024-04-18T10:30:00Z"
    }
  ]
}
"""
