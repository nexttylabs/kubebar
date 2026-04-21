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
            warningEventsCommand: CommandResult(output: warningEventsJSON, error: "", exitCode: 0),
            deploymentsCommand: CommandResult(output: deploymentMetadataJSON, error: "", exitCode: 0)
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
        #expect(snapshot.trackedItems.first?.state == .watch)
        #expect(snapshot.trackedItems.first?.reason == "1 pod not ready")
        #expect(snapshot.trackedItems.first?.affectedPodCount == 1)
        #expect(snapshot.trackedItems.first?.examplePodNames == ["checkout-8a1b"])
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
        let event = snapshot.warningEventsSection.value?.first

        #expect(event?.reason == "BackOff")
        #expect(event?.namespace == "api")
        #expect(event?.objectKind == "Pod")
        #expect(event?.objectName == "checkout-7f9d")
        #expect(event?.message == "Back-off restarting failed container")
        #expect(event?.observedAt == Date(timeIntervalSince1970: 1_713_434_400))
        #expect(event?.count == 3)
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
        let event = snapshot.warningEventsSection.value?.first

        #expect(event?.reason == "FailedScheduling")
        #expect(event?.namespace == "api")
        #expect(event?.objectKind == "Pod")
        #expect(event?.objectName == "checkout-8a1b")
        #expect(event?.message == "0/3 nodes are available")
        #expect(event?.observedAt == Date(timeIntervalSince1970: 1_713_438_000))
        #expect(event?.count == 4)
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

        let forbiddenResource = "secret" + "s"
        #expect(!runner.requests.contains { $0.arguments.contains(forbiddenResource) })
    }

    @Test("missing workload produces no matching pods")
    func missingWorkloadProducesNoMatchingPods() throws {
        let snapshot = try readSnapshot(
            pods: emptyListJSON,
            warningEvents: emptyListJSON,
            watchTargets: [.workload(namespace: "api", name: "checkout")]
        )
        let item = snapshot.trackedItems.first

        #expect(item?.state == .bad)
        #expect(item?.reason == "no matching pods")
        #expect(item?.affectedPodCount == 0)
        #expect(item?.examplePodNames == [])
    }

    @Test("failed pods outrank restarting and not ready pods")
    func failedPodsOutrankRestartingAndNotReadyPods() throws {
        let snapshot = try readSnapshot(
            pods: failedRestartingAndNotReadyPodsJSON,
            warningEvents: emptyListJSON,
            watchTargets: [.workload(namespace: "api", name: "checkout")]
        )
        let item = snapshot.trackedItems.first

        #expect(item?.state == .bad)
        #expect(item?.reason == "2 pods failed")
        #expect(item?.affectedPodCount == 2)
        #expect(item?.examplePodNames == ["checkout-failed", "checkout-failed-b"])
    }

    @Test("restarting reason uses affected pod count")
    func restartingReasonUsesAffectedPodCount() throws {
        let snapshot = try readSnapshot(
            pods: restartingPodsJSON,
            warningEvents: emptyListJSON,
            watchTargets: [.workload(namespace: "api", name: "checkout")]
        )
        let item = snapshot.trackedItems.first

        #expect(item?.state == .bad)
        #expect(item?.reason == "2 pods restarting")
        #expect(item?.affectedPodCount == 2)
        #expect(item?.examplePodNames == ["checkout-a", "checkout-b"])
    }

    @Test("pending and unready pods merge into not ready reason")
    func pendingAndUnreadyPodsMergeIntoNotReadyReason() throws {
        let snapshot = try readSnapshot(
            pods: notReadyPodsJSON,
            warningEvents: emptyListJSON,
            watchTargets: [.workload(namespace: "api", name: "checkout")]
        )
        let item = snapshot.trackedItems.first

        #expect(item?.state == .watch)
        #expect(item?.reason == "3 pods not ready")
        #expect(item?.affectedPodCount == 3)
        #expect(item?.examplePodNames == ["checkout-pending", "checkout-unknown", "checkout-unready"])
    }

    @Test("warning-only target uses latest warning prefix")
    func warningOnlyTargetUsesLatestWarningPrefix() throws {
        let snapshot = try readSnapshot(
            pods: healthyCheckoutPodsJSON,
            warningEvents: warningOnlyEventsJSON,
            watchTargets: [.workload(namespace: "api", name: "checkout")]
        )
        let item = snapshot.trackedItems.first

        #expect(item?.state == .watch)
        #expect(item?.reason.hasPrefix("latest warning:") == true)
        #expect(item?.reason == "latest warning: BackOff")
        #expect(item?.latestWarning?.reason == "BackOff")
    }

    @Test("tracked item detail facts are populated and capped")
    func trackedItemDetailFactsArePopulatedAndCapped() throws {
        let snapshot = try readSnapshot(
            pods: cappedRestartingPodsJSON,
            warningEvents: detailWarningEventsJSON,
            watchTargets: [.workload(namespace: "api", name: "checkout")]
        )
        let item = snapshot.trackedItems.first

        #expect(item?.reason == "4 pods restarting")
        #expect(item?.affectedPodCount == 4)
        #expect(item?.examplePodNames == ["checkout-a", "checkout-b", "checkout-c"])
        #expect(item?.latestWarning?.objectName == "checkout-c")
        #expect(item?.latestWarning?.reason == "BackOff")
    }

    @Test("deployment selector metadata matches workload pods")
    func deploymentSelectorMetadataMatchesWorkloadPods() throws {
        let snapshot = try readSnapshot(
            pods: selectorMatchedPodsJSON,
            warningEvents: emptyListJSON,
            workloadMetadata: selectorDeploymentMetadataJSON,
            watchTargets: [.workload(namespace: "api", name: "checkout")]
        )
        let item = snapshot.trackedItems.first

        #expect(item?.state == .ok)
        #expect(item?.reason == "2/2 pods running")
    }

    @Test("reads independent kubectl resources concurrently")
    func readsIndependentKubectlResourcesConcurrently() throws {
        let runner = SlowRecordingCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: warningEventsJSON, error: "", exitCode: 0),
            deploymentsCommand: CommandResult(output: deploymentMetadataJSON, error: "", exitCode: 0)
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

private let nodesCommand = ["--context", "prod", "get", "nodes", "-o", "json"]
private let podsCommand = ["--context", "prod", "get", "pods", "--all-namespaces", "-o", "json"]
private let warningEventsCommand = ["--context", "prod", "get", "events", "--all-namespaces", "--field-selector", "type=Warning", "-o", "json"]
private let deploymentsCommand = ["--context", "prod", "get", "deployments", "--all-namespaces", "-o", "json"]

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

private let deploymentMetadataJSON = """
{
  "items": [
    {
      "metadata": {"namespace": "api", "name": "checkout"},
      "spec": {"selector": {"matchLabels": {"app.kubernetes.io/name": "checkout"}}}
    }
  ]
}
"""

private let selectorDeploymentMetadataJSON = """
{
  "items": [
    {
      "metadata": {"namespace": "api", "name": "checkout"},
      "spec": {"selector": {"matchLabels": {"component": "payments"}}}
    }
  ]
}
"""

private let failedRestartingAndNotReadyPodsJSON = """
{
  "items": [
    {
      "metadata": {"namespace": "api", "name": "checkout-failed", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {
        "phase": "Failed",
        "containerStatuses": [
          {"ready": false, "restartCount": 3, "state": {"terminated": {"reason": "Error"}}}
        ]
      }
    },
    {
      "metadata": {"namespace": "api", "name": "checkout-failed-b", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {
        "phase": "Failed",
        "containerStatuses": [
          {"ready": false, "restartCount": 0, "state": {"terminated": {"reason": "Error"}}}
        ]
      }
    },
    {
      "metadata": {"namespace": "api", "name": "checkout-restarting", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {
        "phase": "Running",
        "conditions": [{"type": "Ready", "status": "True"}],
        "containerStatuses": [
          {"ready": true, "restartCount": 2}
        ]
      }
    },
    {
      "metadata": {"namespace": "api", "name": "checkout-pending", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {"phase": "Pending"}
    }
  ]
}
"""

private let restartingPodsJSON = """
{
  "items": [
    {
      "metadata": {"namespace": "api", "name": "checkout-a", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {
        "phase": "Running",
        "conditions": [{"type": "Ready", "status": "True"}],
        "containerStatuses": [
          {"ready": true, "restartCount": 1}
        ]
      }
    },
    {
      "metadata": {"namespace": "api", "name": "checkout-b", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {
        "phase": "Running",
        "conditions": [{"type": "Ready", "status": "True"}],
        "containerStatuses": [
          {"ready": true, "restartCount": 0, "state": {"waiting": {"reason": "CrashLoopBackOff"}}}
        ]
      }
    },
    {
      "metadata": {"namespace": "api", "name": "checkout-c", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {
        "phase": "Running",
        "conditions": [{"type": "Ready", "status": "True"}],
        "containerStatuses": [
          {"ready": true, "restartCount": 0}
        ]
      }
    }
  ]
}
"""

private let notReadyPodsJSON = """
{
  "items": [
    {
      "metadata": {"namespace": "api", "name": "checkout-pending", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {"phase": "Pending"}
    },
    {
      "metadata": {"namespace": "api", "name": "checkout-unready", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {
        "phase": "Running",
        "conditions": [{"type": "Ready", "status": "False"}],
        "containerStatuses": [
          {"ready": false, "restartCount": 0}
        ]
      }
    },
    {
      "metadata": {"namespace": "api", "name": "checkout-unknown", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {"phase": "Unknown"}
    }
  ]
}
"""

private let healthyCheckoutPodsJSON = """
{
  "items": [
    {
      "metadata": {"namespace": "api", "name": "checkout-7f9d", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {
        "phase": "Running",
        "conditions": [{"type": "Ready", "status": "True"}],
        "containerStatuses": [
          {"ready": true, "restartCount": 0}
        ]
      }
    }
  ]
}
"""

private let selectorMatchedPodsJSON = """
{
  "items": [
    {
      "metadata": {"namespace": "api", "name": "pod-a", "labels": {"component": "payments"}},
      "status": {
        "phase": "Running",
        "conditions": [{"type": "Ready", "status": "True"}],
        "containerStatuses": [
          {"ready": true, "restartCount": 0}
        ]
      }
    },
    {
      "metadata": {"namespace": "api", "name": "pod-b", "labels": {"component": "payments"}},
      "status": {
        "phase": "Running",
        "conditions": [{"type": "Ready", "status": "True"}],
        "containerStatuses": [
          {"ready": true, "restartCount": 0}
        ]
      }
    }
  ]
}
"""

private let cappedRestartingPodsJSON = """
{
  "items": [
    {
      "metadata": {"namespace": "api", "name": "checkout-d", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {"phase": "Running", "containerStatuses": [{"ready": true, "restartCount": 1}]}
    },
    {
      "metadata": {"namespace": "api", "name": "checkout-b", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {"phase": "Running", "containerStatuses": [{"ready": true, "restartCount": 1}]}
    },
    {
      "metadata": {"namespace": "api", "name": "checkout-a", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {"phase": "Running", "containerStatuses": [{"ready": true, "restartCount": 1}]}
    },
    {
      "metadata": {"namespace": "api", "name": "checkout-c", "labels": {"app.kubernetes.io/name": "checkout"}},
      "status": {"phase": "Running", "containerStatuses": [{"ready": true, "restartCount": 1}]}
    }
  ]
}
"""

private let warningOnlyEventsJSON = """
{
  "items": [
    {
      "metadata": {"namespace": "api", "creationTimestamp": "2024-04-18T09:00:00Z"},
      "reason": "BackOff",
      "message": "Back-off restarting failed container",
      "involvedObject": {"kind": "Pod", "namespace": "api", "name": "checkout-7f9d"},
      "lastTimestamp": "2024-04-18T10:00:00Z",
      "count": 1
    }
  ]
}
"""

private let detailWarningEventsJSON = """
{
  "items": [
    {
      "metadata": {"namespace": "api", "creationTimestamp": "2024-04-18T09:00:00Z"},
      "reason": "FailedScheduling",
      "message": "older warning",
      "involvedObject": {"kind": "Pod", "namespace": "api", "name": "checkout-a"},
      "lastTimestamp": "2024-04-18T09:30:00Z",
      "count": 1
    },
    {
      "metadata": {"namespace": "api", "creationTimestamp": "2024-04-18T09:00:00Z"},
      "reason": "BackOff",
      "message": "newest warning",
      "involvedObject": {"kind": "Pod", "namespace": "api", "name": "checkout-c"},
      "lastTimestamp": "2024-04-18T10:30:00Z",
      "count": 2
    }
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
