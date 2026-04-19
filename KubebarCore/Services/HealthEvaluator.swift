import Foundation

public struct RefreshFailure: Equatable, Sendable {
    public let reason: String

    public init(reason: String) {
        self.reason = reason
    }
}

public struct HealthEvaluator: Sendable {
    private let visibleWatchItemLimit: Int

    public init(visibleWatchItemLimit: Int = 5) {
        self.visibleWatchItemLimit = visibleWatchItemLimit
    }

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
            visibleWatchItems: Array(visibleItems),
            hiddenWatchItemCount: hiddenCount,
            staleBanner: staleBanner(for: resolvedState, snapshot: snapshot, failure: failure, now: now)
        )
    }

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

    private func makeDisplayItem(_ item: TrackedItemStatus) -> WatchItemDisplay {
        WatchItemDisplay(
            id: item.target.displayTitle,
            title: shortened(item.target.displayTitle),
            state: item.state,
            reason: item.reason
        )
    }

    private func healthSentence(for state: ClusterHealthState, visibleItems: [WatchItemDisplay]) -> String {
        switch state {
        case .ok:
            return "Cluster looks healthy"
        case .watch:
            return visibleItems.first(where: { $0.state == .watch })?.title.appending(" needs watching") ?? "Cluster has warnings"
        case .bad:
            return visibleItems.first(where: { $0.state == .bad })?.title.appending(" needs attention") ?? "Cluster needs attention"
        case .stale:
            return "Last cluster status is stale"
        }
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

        return StaleBannerDisplay(
            lastUpdated: relativeAge(from: snapshot.capturedAt, to: now),
            reason: failure?.reason ?? "Refresh failed"
        )
    }

    private func relativeAge(from date: Date, to now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))

        if seconds < 60 {
            return "\(seconds)s ago"
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m ago"
        }

        return "\(minutes / 60)h ago"
    }

    private func shortened(_ value: String, limit: Int = 42) -> String {
        guard value.count > limit else {
            return value
        }

        return String(value.prefix(limit - 1)) + "…"
    }
}
