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

    func readSnapshot(contextName: String, watchTargets: [WatchTarget], now: Date) throws -> ClusterSnapshot {
        try result.get()
    }
}
