import Foundation
import Testing
@testable import KubebarCore

@Suite("Menu display model")
struct MenuDisplayModelTests {
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

    @Test("long watch item titles truncate consistently")
    func longWatchItemTitlesTruncateConsistently() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 1, total: 1),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(
                    target: .workload(namespace: "production-namespace", name: "checkout-api-with-a-very-long-name"),
                    state: .ok,
                    reason: "ready"
                )
            ],
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.visibleWatchItems.first?.title == "production-namespace/checkout-api-with-a-…")
    }

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
}
