import Foundation
import Testing
@testable import KubebarCore

@Suite("Refresh coordinator")
struct RefreshCoordinatorTests {
    @Test("configured refresh returns current display and snapshot")
    func configuredRefreshReturnsCurrentDisplayAndSnapshot() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 1, total: 1),
            podSummary: PodSummary(running: 1, total: 1),
            warningEventCount: 0,
            trackedItems: [.init(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "1/1 pods running")],
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let coordinator = RefreshCoordinator(reader: FakeClusterReader(result: .success(snapshot)))

        let result = coordinator.refresh(
            config: AppConfig(selectedContext: "prod", watchTargets: [.workload(namespace: "api", name: "checkout")]),
            previousSnapshot: nil,
            now: Date(timeIntervalSince1970: 100)
        )

        #expect(result.snapshot == snapshot)
        #expect(result.display.state == .ok)
    }

    @Test("refresh uses active context watchlist")
    func refreshUsesActiveContextWatchlist() {
        let snapshot = ClusterSnapshot(
            contextName: "stage",
            nodeSummary: NodeSummary(ready: 1, total: 1),
            podSummary: PodSummary(running: 1, total: 1),
            warningEventCount: 0,
            trackedItems: [.init(target: .namespace("web"), state: .ok, reason: "1/1 pods running")],
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let reader = RecordingClusterReader(result: .success(snapshot))
        let coordinator = RefreshCoordinator(reader: reader)

        _ = coordinator.refresh(
            config: AppConfig(
                selectedContext: "stage",
                watchlistsByContext: [
                    "prod": [.namespace("api")],
                    "stage": [.namespace("web")]
                ]
            ),
            previousSnapshot: nil,
            now: Date(timeIntervalSince1970: 100)
        )

        #expect(reader.lastContextName == "stage")
        #expect(reader.lastWatchTargets == [.namespace("web")])
    }

    @Test("refresh passes config kubeconfig paths through cluster reads")
    func refreshPassesConfigKubeconfigPathsThroughClusterReads() {
        let snapshot = ClusterSnapshot(
            contextName: "stage",
            nodeSummary: NodeSummary(ready: 1, total: 1),
            podSummary: PodSummary(running: 1, total: 1),
            warningEventCount: 0,
            trackedItems: [.init(target: .namespace("web"), state: .ok, reason: "1/1 pods running")],
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let reader = RecordingClusterReader(result: .success(snapshot))
        let coordinator = RefreshCoordinator(reader: reader)

        _ = coordinator.refresh(
            config: AppConfig(
                selectedContext: "stage",
                watchTargets: [.namespace("web")],
                kubeconfigPaths: ["/tmp/dev.yaml", "/tmp/prod.yaml"]
            ),
            previousSnapshot: nil,
            now: Date(timeIntervalSince1970: 100)
        )

        #expect(reader.lastConfig?.kubeconfigPaths == ["/tmp/dev.yaml", "/tmp/prod.yaml"])
    }

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

    @Test("failed refresh with no previous snapshot shows no previous data")
    func failedRefreshWithNoPreviousSnapshotShowsNoPreviousData() {
        let coordinator = RefreshCoordinator(reader: FakeClusterReader(result: .failure(KubectlCommandError.failed("kubectl timed out"))))

        let result = coordinator.refresh(
            config: AppConfig(selectedContext: "prod", watchTargets: [.workload(namespace: "api", name: "checkout")]),
            previousSnapshot: nil,
            now: Date(timeIntervalSince1970: 220)
        )

        #expect(result.snapshot == nil)
        #expect(result.display.state == .stale)
        #expect(result.display.lastUpdated == "never")
        #expect(result.display.staleBanner?.reason == "No previous cluster data")
    }

    @Test("second failed refresh keeps previous snapshot and updates reason")
    func secondFailedRefreshKeepsPreviousSnapshotAndUpdatesReason() {
        let previous = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 12, total: 12),
            warningEventCount: 0,
            trackedItems: [.init(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "6/6 pods running")],
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let firstFailure = RefreshCoordinator(reader: FakeClusterReader(result: .failure(KubectlCommandError.failed("cluster unreachable"))))
        let secondFailure = RefreshCoordinator(reader: FakeClusterReader(result: .failure(KubectlCommandError.failed("kubectl timed out"))))

        let first = firstFailure.refresh(
            config: AppConfig(selectedContext: "prod", watchTargets: [.workload(namespace: "api", name: "checkout")]),
            previousSnapshot: previous,
            now: Date(timeIntervalSince1970: 220)
        )
        let second = secondFailure.refresh(
            config: AppConfig(selectedContext: "prod", watchTargets: [.workload(namespace: "api", name: "checkout")]),
            previousSnapshot: first.snapshot,
            now: Date(timeIntervalSince1970: 260)
        )

        #expect(first.snapshot == previous)
        #expect(second.snapshot == previous)
        #expect(second.display.state == .stale)
        #expect(second.display.counters.nodes == "3/3")
        #expect(second.display.visibleWatchItems.first?.title == "api/checkout")
        #expect(second.display.staleBanner?.reason == "kubectl timed out")
    }

    @Test("partial warning event failure stays fresh and visible")
    func partialWarningEventFailureStaysFreshAndVisible() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 1, total: 1)),
            podsSection: .available(PodSummary(running: 1, total: 1)),
            warningEventsSection: .unavailable(reason: "invalid event JSON"),
            workloadsSection: .available([
                .init(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "1/1 pods running")
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let coordinator = RefreshCoordinator(reader: FakeClusterReader(result: .success(snapshot)))

        let result = coordinator.refresh(
            config: AppConfig(selectedContext: "prod", watchTargets: [.workload(namespace: "api", name: "checkout")]),
            previousSnapshot: nil,
            now: Date(timeIntervalSince1970: 120)
        )

        #expect(result.snapshot == snapshot)
        #expect(result.display.state == .watch)
        #expect(result.display.sectionNotices.contains { $0.title == "Warning events" && $0.reason == "invalid event JSON" })
        #expect(result.display.staleBanner == nil)
    }

    @Test("successful refresh uses injected date and saved cadence for stale age")
    func successfulRefreshUsesInjectedDateAndSavedCadenceForStaleAge() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 1, total: 1),
            podSummary: PodSummary(running: 1, total: 1),
            warningEventCount: 0,
            trackedItems: [.init(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "1/1 pods running")],
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let coordinator = RefreshCoordinator(reader: FakeClusterReader(result: .success(snapshot)))

        let result = coordinator.refresh(
            config: AppConfig(
                selectedContext: "prod",
                watchTargets: [.workload(namespace: "api", name: "checkout")],
                refreshIntervalSeconds: 60
            ),
            previousSnapshot: nil,
            now: Date(timeIntervalSince1970: 221)
        )

        #expect(result.snapshot == snapshot)
        #expect(result.display.state == .stale)
        #expect(result.display.lastUpdated == "2m ago")
        #expect(result.display.staleBanner?.reason == "Last refresh is too old")
    }

    @Test("missing setup returns unavailable display")
    func missingSetupReturnsUnavailableDisplay() {
        let coordinator = RefreshCoordinator(reader: FakeClusterReader(result: .failure(KubectlCommandError.failed("should not run"))))

        let result = coordinator.refresh(config: AppConfig(), previousSnapshot: nil, now: Date())

        #expect(result.snapshot == nil)
        #expect(result.display.state == .stale)
        #expect(result.display.contextName == "Not configured")
    }
}

private struct FakeClusterReader: ClusterReading {
    let result: Result<ClusterSnapshot, Error>

    func readSnapshot(config: AppConfig, contextName: String, watchTargets: [WatchTarget], now: Date) throws -> ClusterSnapshot {
        try result.get()
    }
}

private final class RecordingClusterReader: ClusterReading, @unchecked Sendable {
    private let result: Result<ClusterSnapshot, Error>
    private(set) var lastConfig: AppConfig?
    private(set) var lastContextName: String?
    private(set) var lastWatchTargets: [WatchTarget] = []

    init(result: Result<ClusterSnapshot, Error>) {
        self.result = result
    }

    func readSnapshot(config: AppConfig, contextName: String, watchTargets: [WatchTarget], now: Date) throws -> ClusterSnapshot {
        lastConfig = config
        lastContextName = contextName
        lastWatchTargets = watchTargets
        return try result.get()
    }
}
