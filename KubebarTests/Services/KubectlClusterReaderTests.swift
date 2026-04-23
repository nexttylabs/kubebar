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
            nodeMetricsCommand: CommandResult(output: nodeMetricsJSON, error: "", exitCode: 0),
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
        #expect(snapshot.metricsSection.value?.cpuUsageNanocores == 750_000_000)
        #expect(snapshot.metricsSection.value?.cpuAllocatableNanocores == 3_500_000_000)
        #expect(snapshot.metricsSection.value?.memoryUsageBytes == 2_147_483_648)
        #expect(snapshot.metricsSection.value?.memoryAllocatableBytes == 12_884_901_888)
        #expect(snapshot.trackedItems.first?.state == .watch)
        #expect(snapshot.trackedItems.first?.reason == "1 pod not ready")
        #expect(snapshot.trackedItems.first?.affectedPodCount == 1)
        #expect(snapshot.trackedItems.first?.examplePodNames == ["checkout-8a1b"])
    }

    @Test("builds per-node detail rows from node and metrics JSON")
    func buildsPerNodeDetailRowsFromNodeAndMetricsJSON() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodeDetailsJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0),
            nodeMetricsCommand: CommandResult(output: nodeDetailsMetricsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))
        let rows = try #require(snapshot.nodeDetailsSection.value)

        #expect(rows.count == 2)
        #expect(rows[0].name == "worker-a")
        #expect(rows[0].isReady == true)
        #expect(rows[0].cpuUsageNanocores == 500_000_000)
        #expect(rows[0].cpuAllocatableNanocores == 2_000_000_000)
        #expect(rows[0].memoryUsageBytes == 1_073_741_824)
        #expect(rows[0].memoryAllocatableBytes == 8_589_934_592)
        #expect(rows[1].name == "worker-b")
        #expect(rows[1].isReady == false)
        #expect(rows[1].issueReason == "KubeletNotReady")
        #expect(rows[1].issueMessage == "container runtime is down")
        #expect(rows[1].cpuUsageNanocores == 250_000_000)
        #expect(rows[1].cpuAllocatableNanocores == 1_500_000_000)
        #expect(rows[1].memoryUsageBytes == 1_073_741_824)
        #expect(rows[1].memoryAllocatableBytes == 4_294_967_296)
    }

    @Test("metrics failure keeps per-node detail rows without usage")
    func metricsFailureKeepsPerNodeDetailRowsWithoutUsage() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodeDetailsJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0),
            nodeMetricsCommand: CommandResult(output: "", error: "metrics API unavailable", exitCode: 1),
            warningEventsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))
        let rows = try #require(snapshot.nodeDetailsSection.value)

        #expect(rows.map(\.name) == ["worker-a", "worker-b"])
        #expect(rows.allSatisfy { $0.cpuUsageNanocores == nil })
        #expect(rows.allSatisfy { $0.memoryUsageBytes == nil })
    }

    @Test("unknown ready condition is treated as not ready")
    func unknownReadyConditionIsTreatedAsNotReady() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: unknownReadyNodeJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0),
            nodeMetricsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))
        let row = try #require(snapshot.nodeDetailsSection.value?.first)

        #expect(row.name == "worker-missing")
        #expect(row.isReady == false)
        #expect(row.issueReason == "NodeStatusUnknown")
        #expect(row.issueMessage == "Kubelet stopped posting node status.")
    }

    @Test("pressure condition is surfaced as a not ready node issue")
    func pressureConditionIsSurfacedAsNotReadyNodeIssue() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: pressureNodeJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0),
            nodeMetricsCommand: CommandResult(output: pressureNodeMetricsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))
        let row = try #require(snapshot.nodeDetailsSection.value?.first)

        #expect(snapshot.nodesSection.value == NodeSummary(ready: 0, total: 1))
        #expect(row.name == "worker-pressure")
        #expect(row.isReady == false)
        #expect(row.issueReason == "KubeletHasDiskPressure")
        #expect(row.issueMessage == "kubelet has disk pressure")
    }

    @Test("metrics API failure only marks metrics unavailable")
    func metricsAPIFailureOnlyMarksMetricsUnavailable() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            nodeMetricsCommand: CommandResult(output: "", error: "metrics API unavailable", exitCode: 1),
            warningEventsCommand: CommandResult(output: warningEventsJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))

        #expect(snapshot.nodesSection.isAvailable == true)
        #expect(snapshot.podsSection.isAvailable == true)
        #expect(snapshot.metricsSection.unavailableReason == "metrics API unavailable")
        #expect(snapshot.sectionFailures == [])
    }

    @Test("malformed metrics JSON only marks metrics unavailable")
    func malformedMetricsJSONOnlyMarksMetricsUnavailable() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            nodeMetricsCommand: CommandResult(output: "{", error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: warningEventsJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))

        #expect(snapshot.metricsSection.unavailableReason == "invalid metrics JSON")
        #expect(snapshot.warningEventsSection.isAvailable == true)
        #expect(snapshot.sectionFailures == [])
    }

    @Test("missing node allocatable makes metrics unavailable")
    func missingNodeAllocatableMakesMetricsUnavailable() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: nodesWithoutAllocatableJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: podsJSON, error: "", exitCode: 0),
            nodeMetricsCommand: CommandResult(output: nodeMetricsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: warningEventsJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))

        #expect(snapshot.metricsSection.unavailableReason == "missing node allocatable")
    }

    @Test("zero metrics and exponent quantities are valid")
    func zeroMetricsAndExponentQuantitiesAreValid() throws {
        let runner = FakeMultiCommandRunner(results: [
            nodesCommand: CommandResult(output: exponentNodesJSON, error: "", exitCode: 0),
            podsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0),
            nodeMetricsCommand: CommandResult(output: zeroNodeMetricsJSON, error: "", exitCode: 0),
            warningEventsCommand: CommandResult(output: emptyListJSON, error: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date(timeIntervalSince1970: 100))

        #expect(snapshot.metricsSection.value?.cpuUsageNanocores == 0)
        #expect(snapshot.metricsSection.value?.cpuAllocatableNanocores == 1_000_000_000)
        #expect(snapshot.metricsSection.value?.memoryUsageBytes == 0)
        #expect(snapshot.metricsSection.value?.memoryAllocatableBytes == 2_000_000_000)
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

    @Test("kubectl timeout reports short timeout reason")
    func kubectlTimeoutReportsShortTimeoutReason() {
        let reader = KubectlClusterReader(runner: ThrowingCommandRunner(error: CommandRunnerError.timedOut))

        #expect(throws: KubectlCommandError.failed("kubectl timed out")) {
            try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date())
        }
    }

    @Test("kubectl command failure falls back for empty or unsafe stderr")
    func kubectlCommandFailureFallsBackForEmptyOrUnsafeStderr() {
        let emptyStderrReader = KubectlClusterReader(
            runner: RecordingCommandRunner(result: CommandResult(output: "", error: "", exitCode: 1))
        )
        let unsafeStderrReader = KubectlClusterReader(
            runner: RecordingCommandRunner(result: CommandResult(output: "", error: "token expired for cluster", exitCode: 1))
        )

        #expect(throws: KubectlCommandError.failed("kubectl failed")) {
            try emptyStderrReader.readSnapshot(contextName: "prod", watchTargets: [], now: Date())
        }
        #expect(throws: KubectlCommandError.failed("kubectl failed")) {
            try unsafeStderrReader.readSnapshot(contextName: "prod", watchTargets: [], now: Date())
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

        #expect(item?.state == .watch)
        #expect(item?.reason == "no matching pods")
        #expect(item?.affectedPodCount == nil)
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

    @Test("namespace target preserves watched pod details")
    func namespaceTargetPreservesWatchedPodDetails() throws {
        let snapshot = try readSnapshot(
            pods: podsJSON,
            warningEvents: emptyListJSON,
            watchTargets: [.namespace("api")]
        )
        let details = try #require(snapshot.podDetailsSection.value)

        #expect(details.map(\.name).sorted() == ["checkout-7f9d", "checkout-8a1b", "checkout-worker-1"])
        #expect(details.allSatisfy { $0.namespace == "api" })
    }

    @Test("workload target preserves only matching pod details")
    func workloadTargetPreservesOnlyMatchingPodDetails() throws {
        let snapshot = try readSnapshot(
            pods: podsJSON,
            warningEvents: emptyListJSON,
            watchTargets: [.workload(namespace: "api", name: "checkout")]
        )
        let details = try #require(snapshot.podDetailsSection.value)

        #expect(details.map(\.name).sorted() == ["checkout-7f9d", "checkout-8a1b"])
    }

    @Test("overlapping watched targets deduplicate pod details")
    func overlappingWatchedTargetsDeduplicatePodDetails() throws {
        let snapshot = try readSnapshot(
            pods: podsJSON,
            warningEvents: emptyListJSON,
            watchTargets: [
                .namespace("api"),
                .workload(namespace: "api", name: "checkout")
            ]
        )
        let details = try #require(snapshot.podDetailsSection.value)

        #expect(details.map(\.name).sorted() == ["checkout-7f9d", "checkout-8a1b", "checkout-worker-1"])
    }

    @Test("pod details preserve container readiness facts")
    func podDetailsPreserveContainerReadinessFacts() throws {
        let snapshot = try readSnapshot(
            pods: partiallyReadyPodJSON,
            warningEvents: emptyListJSON,
            watchTargets: [.namespace("api")]
        )
        let detail = try #require(snapshot.podDetailsSection.value?.first)

        #expect(detail.readyContainerCount == 1)
        #expect(detail.totalContainerCount == 2)
        #expect(detail.isNotReady == true)
        #expect(detail.notReadyConditionReason == "ContainersNotReady")
    }

    @Test("pod detail failures preserve safe unavailable reasons")
    func podDetailFailuresPreserveSafeUnavailableReasons() throws {
        let invalidPods = try readSnapshot(
            pods: "{",
            warningEvents: emptyListJSON,
            watchTargets: [.namespace("api")]
        )
        let invalidWorkload = try readSnapshot(
            pods: podsJSON,
            warningEvents: emptyListJSON,
            workloadMetadata: "{",
            watchTargets: [.workload(namespace: "api", name: "checkout")]
        )

        #expect(invalidPods.podDetailsSection.unavailableReason == "invalid pod JSON")
        #expect(invalidWorkload.podDetailsSection.unavailableReason == "invalid workload JSON")
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

private struct ThrowingCommandRunner: CommandRunning {
    let error: Error

    func run(_ request: CommandRequest) throws -> CommandResult {
        throw error
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
private let nodeMetricsCommand = ["--context", "prod", "get", "--raw", "/apis/metrics.k8s.io/v1beta1/nodes"]
private let warningEventsCommand = ["--context", "prod", "get", "events", "--all-namespaces", "--field-selector", "type=Warning", "-o", "json"]
private let deploymentsCommand = ["--context", "prod", "get", "deployments", "--all-namespaces", "-o", "json"]

private let nodesJSON = """
{
  "items": [
    {"metadata": {"name": "worker-a"}, "status": {"allocatable": {"cpu": "2", "memory": "8Gi"}, "conditions": [{"type": "Ready", "status": "True"}]}},
    {"metadata": {"name": "worker-b"}, "status": {"allocatable": {"cpu": "1500m", "memory": "4096Mi"}, "conditions": [{"type": "Ready", "status": "False"}]}}
  ]
}
"""

private let nodesWithoutAllocatableJSON = """
{
  "items": [
    {"metadata": {"name": "worker-a"}, "status": {"conditions": [{"type": "Ready", "status": "True"}]}},
    {"metadata": {"name": "worker-b"}, "status": {"conditions": [{"type": "Ready", "status": "False"}]}}
  ]
}
"""

private let nodeMetricsJSON = """
{
  "items": [
    {"metadata": {"name": "worker-a"}, "usage": {"cpu": "500m", "memory": "1024Mi"}},
    {"metadata": {"name": "worker-b"}, "usage": {"cpu": "250000000n", "memory": "1Gi"}}
  ]
}
"""

private let exponentNodesJSON = """
{
  "items": [
    {"metadata": {"name": "worker-exponent"}, "status": {"allocatable": {"cpu": "1e0", "memory": "2G"}, "conditions": [{"type": "Ready", "status": "True"}]}}
  ]
}
"""

private let zeroNodeMetricsJSON = """
{
  "items": [
    {"metadata": {"name": "worker-exponent"}, "usage": {"cpu": "0", "memory": "0"}}
  ]
}
"""

private let nodeDetailsJSON = """
{
  "items": [
    {
      "metadata": {"name": "worker-a"},
      "status": {
        "allocatable": {"cpu": "2", "memory": "8Gi"},
        "conditions": [
          {"type": "Ready", "status": "True", "reason": "KubeletReady", "message": "kubelet is posting ready status"}
        ]
      }
    },
    {
      "metadata": {"name": "worker-b"},
      "status": {
        "allocatable": {"cpu": "1500m", "memory": "4096Mi"},
        "conditions": [
          {"type": "Ready", "status": "False", "reason": "KubeletNotReady", "message": "container runtime is down"}
        ]
      }
    }
  ]
}
"""

private let nodeDetailsMetricsJSON = """
{
  "items": [
    {"metadata": {"name": "worker-a"}, "usage": {"cpu": "500m", "memory": "1024Mi"}},
    {"metadata": {"name": "worker-b"}, "usage": {"cpu": "250000000n", "memory": "1Gi"}}
  ]
}
"""

private let unknownReadyNodeJSON = """
{
  "items": [
    {
      "metadata": {"name": "worker-missing"},
      "status": {
        "allocatable": {"cpu": "1", "memory": "2Gi"},
        "conditions": [
          {"type": "Ready", "status": "Unknown", "reason": "NodeStatusUnknown", "message": "Kubelet stopped posting node status."}
        ]
      }
    }
  ]
}
"""

private let pressureNodeJSON = """
{
  "items": [
    {
      "metadata": {"name": "worker-pressure"},
      "status": {
        "allocatable": {"cpu": "2", "memory": "8Gi"},
        "conditions": [
          {"type": "Ready", "status": "True", "reason": "KubeletReady", "message": "kubelet is posting ready status"},
          {"type": "DiskPressure", "status": "True", "reason": "KubeletHasDiskPressure", "message": "kubelet has disk pressure"}
        ]
      }
    }
  ]
}
"""

private let pressureNodeMetricsJSON = """
{
  "items": [
    {"metadata": {"name": "worker-pressure"}, "usage": {"cpu": "500m", "memory": "1024Mi"}}
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

private let partiallyReadyPodJSON = """
{
  "items": [
    {
      "metadata": {"namespace": "api", "name": "checkout-partial"},
      "status": {
        "phase": "Running",
        "conditions": [
          {"type": "ContainersReady", "status": "False", "reason": "ContainersNotReady", "message": "containers with unready status"}
        ],
        "containerStatuses": [
          {"ready": true, "restartCount": 0},
          {"ready": false, "restartCount": 0}
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
