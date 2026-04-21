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
        #expect(display.primaryStatusReason == "Cluster looks healthy")
        #expect(display.lastUpdated == "20s ago")
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
        #expect(display.primaryStatusReason == "1 pod pending")
    }

    @Test("warning events provide primary status reason")
    func warningEventsProvidePrimaryStatusReason() {
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

        #expect(display.state == .watch)
        #expect(display.primaryStatusReason == "2 warning events")
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

    @Test("long watch item titles stay full for middle truncation")
    func longWatchItemTitlesStayFullForMiddleTruncation() {
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

        #expect(display.visibleWatchItems.first?.title == "production-namespace/checkout-api-with-a-very-long-name")
    }

    @Test("similar long watch item titles keep suffix differences")
    func similarLongWatchItemTitlesKeepSuffixDifferences() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 2, total: 2),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(
                    target: .workload(namespace: "production-namespace", name: "checkout-api-with-shared-long-prefix-api"),
                    state: .ok,
                    reason: "ready"
                ),
                TrackedItemStatus(
                    target: .workload(namespace: "production-namespace", name: "checkout-worker-with-shared-long-prefix-worker"),
                    state: .ok,
                    reason: "ready"
                )
            ],
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let titles = display.visibleWatchItems.map(\.title)

        #expect(titles == [
            "production-namespace/checkout-api-with-shared-long-prefix-api",
            "production-namespace/checkout-worker-with-shared-long-prefix-worker"
        ])
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
        #expect(display.lastUpdated == "2m ago")
        #expect(display.staleBanner?.lastUpdated == "2m ago")
        #expect(display.staleBanner?.reason == "kubectl timed out")
        #expect(display.primaryStatusReason == "kubectl timed out")
        #expect(display.visibleWatchItems.first?.title == "api/checkout")
    }

    @Test("old healthy snapshot becomes stale after freshness window")
    func oldHealthySnapshotBecomesStaleAfterFreshnessWindow() {
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

        let display = HealthEvaluator().evaluate(
            snapshot: snapshot,
            now: Date(timeIntervalSince1970: 221),
            staleAfterSeconds: 120
        )

        #expect(display.state == .stale)
        #expect(display.contextName == "prod")
        #expect(display.counters.nodes == "3/3")
        #expect(display.visibleWatchItems.first?.title == "api/checkout")
        #expect(display.lastUpdated == "2m ago")
        #expect(display.staleBanner?.reason == "Last refresh is too old")
    }

    @Test("watch item detail defaults to row reason")
    func watchItemDetailDefaultsToRowReason() {
        let item = WatchItemDisplay(
            id: "api/checkout",
            title: "api/checkout",
            state: .watch,
            reason: "1 pod not ready"
        )

        #expect(item.detail.reason == "1 pod not ready")
    }

    @Test("warning event display summary includes occurrence count only when repeated")
    func warningEventDisplaySummaryIncludesOccurrenceCountOnlyWhenRepeated() {
        let single = WarningEventDisplay(
            id: "single",
            reason: "BackOff",
            location: "api/pod/checkout",
            age: "2m ago",
            occurrenceCount: 1,
            message: nil
        )
        let repeated = WarningEventDisplay(
            id: "repeated",
            reason: "BackOff",
            location: "api/pod/checkout",
            age: "2m ago",
            occurrenceCount: 4,
            message: nil
        )

        #expect(single.summary == "BackOff api/pod/checkout 2m ago")
        #expect(repeated.summary == "BackOff x4 api/pod/checkout 2m ago")
    }

    @Test("duplicate warning events group into one warning summaries row")
    func duplicateWarningEventsGroupIntoOneWarningSummaryRow() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(reason: "BackOff", observedAt: Date(timeIntervalSince1970: 90), count: 1, message: "older warning"),
                warningEvent(reason: "BackOff", observedAt: Date(timeIntervalSince1970: 100), count: 3, message: "newest warning")
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.warningEventSummaries.count == 1)
        #expect(display.warningEventSummaries.first?.occurrenceCount == 4)
        #expect(display.warningEventSummaries.first?.summary == "BackOff x4 api/pod/checkout 2m ago")
        #expect(display.warningEventSummaries.first?.message == "newest warning")
    }

    @Test("warning summaries are capped at three rows")
    func warningSummariesAreCappedAtThreeRows() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(reason: "BackOff", objectName: "checkout-a", observedAt: Date(timeIntervalSince1970: 100), count: 1),
                warningEvent(reason: "FailedScheduling", objectName: "checkout-b", observedAt: Date(timeIntervalSince1970: 90), count: 1),
                warningEvent(reason: "Unhealthy", objectName: "checkout-c", observedAt: Date(timeIntervalSince1970: 80), count: 1),
                warningEvent(reason: "Pulled", objectName: "checkout-d", observedAt: Date(timeIntervalSince1970: 70), count: 1)
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.warningEventSummaries.count == 3)
    }

    @Test("long warning message is shortened before display")
    func longWarningMessageIsShortenedBeforeDisplay() {
        let longWarning = String(repeating: "a", count: 140)
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(reason: "BackOff", observedAt: Date(timeIntervalSince1970: 100), count: 1, message: longWarning)
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.warningEventSummaries.first?.message?.count == 96)
        #expect(display.warningEventSummaries.first?.message != longWarning)
    }

    @Test("tracked item detail.examplePodNames are capped at three")
    func trackedItemDetailExamplePodNamesAreCappedAtThree() {
        let item = TrackedItemStatus(
            target: .workload(namespace: "api", name: "checkout"),
            state: .bad,
            reason: "5 pods restarting",
            affectedPodCount: 5,
            examplePodNames: ["checkout-a", "checkout-b", "checkout-c", "checkout-d", "checkout-e"]
        )
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 7, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .available([item]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.visibleWatchItems.first?.detail.examplePodNames == ["checkout-a", "checkout-b", "checkout-c"])
    }

    @Test("tracked item detail includes affected pod count and latest warning")
    func trackedItemDetailIncludesAffectedPodCountAndLatestWarning() {
        let latestWarning = warningEvent(reason: "BackOff", observedAt: Date(timeIntervalSince1970: 100), count: 2, message: "newest warning")
        let item = TrackedItemStatus(
            target: .workload(namespace: "api", name: "checkout"),
            state: .bad,
            reason: "2 pods restarting",
            affectedPodCount: 2,
            examplePodNames: ["checkout-a", "checkout-b"],
            latestWarning: latestWarning
        )
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 10, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .available([item]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.visibleWatchItems.first?.detail.affectedPodCount == 2)
        #expect(display.visibleWatchItems.first?.detail.latestWarning?.reason == "BackOff")
        #expect(display.visibleWatchItems.first?.detail.latestWarning?.occurrenceCount == 2)
    }

    @Test("unavailable warning events use dash counter and watch state")
    func unavailableWarningEventsUseDashCounterAndWatchState() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .unavailable(reason: "invalid event JSON"),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.counters.warningEvents == "-")
        #expect(display.state == .watch)
        #expect(display.primaryStatusReason == "invalid event JSON")
        #expect(display.sectionNotices.contains { $0.title == "Warning events" && $0.reason == "invalid event JSON" })
    }

    @Test("unavailable pods use dash counter")
    func unavailablePodsUseDashCounter() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .unavailable(reason: "invalid pod JSON"),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.counters.pods == "-")
        #expect(display.state == .watch)
    }

    @Test("unavailable section prevents otherwise healthy ok state")
    func unavailableSectionPreventsOtherwiseHealthyOKState() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .unavailable(reason: "invalid workload JSON"),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.state == .watch)
    }
}

private func warningEvent(
    reason: String,
    namespace: String? = "api",
    objectKind: String? = "Pod",
    objectName: String? = "checkout",
    observedAt: Date?,
    count: Int,
    message: String? = nil
) -> WarningEventRecord {
    WarningEventRecord(
        reason: reason,
        namespace: namespace,
        objectKind: objectKind,
        objectName: objectName,
        message: message,
        observedAt: observedAt,
        count: count
    )
}
