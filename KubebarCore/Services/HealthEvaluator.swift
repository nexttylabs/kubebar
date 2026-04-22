import Foundation

public struct RefreshFailure: Equatable, Sendable {
    public let reason: String

    public init(reason: String) {
        self.reason = reason
    }
}

public struct HealthEvaluator: Sendable {
    private let visibleWatchItemLimit: Int
    private let warningEventSummaryLimit = 3
    private let warningMessageLimit = 96

    public init(visibleWatchItemLimit: Int = 5) {
        self.visibleWatchItemLimit = visibleWatchItemLimit
    }

    public func evaluate(
        snapshot: ClusterSnapshot?,
        previousSnapshot: ClusterSnapshot? = nil,
        failure: RefreshFailure? = nil,
        now: Date,
        staleAfterSeconds: Int? = nil
    ) -> MenuDisplayModel {
        if let snapshot {
            return displayModel(
                from: snapshot,
                stateOverride: nil,
                failureReason: failure?.reason,
                now: now,
                staleAfterSeconds: staleAfterSeconds
            )
        }

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
    }

    private func displayModel(
        from snapshot: ClusterSnapshot,
        stateOverride: ClusterHealthState?,
        failureReason: String?,
        now: Date,
        staleAfterSeconds: Int?
    ) -> MenuDisplayModel {
        let sortedItems = sortByAttention(snapshot.trackedItems)
        let visibleItems = sortedItems.prefix(visibleWatchItemLimit).map { makeDisplayItem($0, now: now) }
        let hiddenCount = max(0, sortedItems.count - visibleItems.count)
        let freshnessReason = staleAgeOutReason(for: snapshot, now: now, staleAfterSeconds: staleAfterSeconds)
        let resolvedState = stateOverride ?? (freshnessReason == nil ? evaluateState(snapshot) : .stale)
        let warningEventSummaries = makeWarningEventSummaries(from: snapshot.warningEventsSection.value ?? [], now: now)
        let sectionNotices = makeSectionNotices(from: snapshot.sectionFailures)
        let staleReason = failureReason ?? freshnessReason
        let lastUpdated = relativeAge(from: snapshot.capturedAt, to: now)

        return MenuDisplayModel(
            state: resolvedState,
            contextName: snapshot.contextName,
            healthSentence: healthSentence(for: resolvedState, visibleItems: visibleItems),
            primaryStatusReason: primaryStatusReason(for: resolvedState, snapshot: snapshot, visibleItems: visibleItems, sectionNotices: sectionNotices, staleReason: staleReason),
            lastUpdated: lastUpdated,
            counters: menuCounters(from: snapshot),
            visibleWatchItems: visibleItems,
            hiddenWatchItemCount: hiddenCount,
            staleBanner: staleBanner(
                for: resolvedState,
                snapshot: snapshot,
                failureReason: staleReason,
                now: now
            ),
            warningEventSummaries: warningEventSummaries,
            sectionNotices: sectionNotices,
            overviewNotice: makeOverviewNotice(sectionNotices: sectionNotices, warningEventSummaries: warningEventSummaries),
            nodeTab: makeNodeTab(from: snapshot, sectionNotices: sectionNotices),
            podTab: makePodTab(from: snapshot, visibleItems: Array(visibleItems), sectionNotices: sectionNotices),
            eventsTab: makeEventsTab(rows: warningEventSummaries, sectionNotices: sectionNotices)
        )
    }

    private func staleAgeOutReason(for snapshot: ClusterSnapshot, now: Date, staleAfterSeconds: Int?) -> String? {
        guard let staleAfterSeconds else {
            return nil
        }

        let ageSeconds = max(0, Int(now.timeIntervalSince(snapshot.capturedAt)))
        return ageSeconds > staleAfterSeconds ? "Last refresh is too old" : nil
    }

    private func evaluateState(_ snapshot: ClusterSnapshot) -> ClusterHealthState {
        if snapshot.nodesSection.value.map({ $0.ready < $0.total }) == true ||
            snapshot.trackedItems.contains(where: { $0.state == .bad }) {
            return .bad
        }

        if snapshot.podsSection.value.map({ $0.running < $0.total }) == true ||
            snapshot.warningEventsSection.value.map({ !$0.isEmpty }) == true ||
            snapshot.trackedItems.contains(where: { $0.state == .watch }) ||
            !snapshot.sectionFailures.isEmpty {
            return .watch
        }

        return .ok
    }

    private func menuCounters(from snapshot: ClusterSnapshot) -> MenuCounters {
        MenuCounters(
            nodes: snapshot.nodesSection.value.map { "\($0.ready)/\($0.total)" } ?? "-",
            pods: snapshot.podsSection.value.map { "\($0.running)/\($0.total)" } ?? "-",
            warningEvents: snapshot.warningEventsSection.value.map { _ in "\(snapshot.warningEventCount)" } ?? "-"
        )
    }

    private func makeSectionNotices(from sectionFailures: [SnapshotSectionFailure]) -> [SectionAvailabilityDisplay] {
        sectionFailures.map { failure in
            SectionAvailabilityDisplay(
                id: failure.section.rawValue,
                title: failure.section.displayName,
                reason: sanitizedSectionReason(failure.reason)
            )
        }
    }

    private func makeOverviewNotice(
        sectionNotices: [SectionAvailabilityDisplay],
        warningEventSummaries: [WarningEventDisplay]
    ) -> OverviewNoticeDisplay? {
        if let notice = sectionNotices.first {
            return OverviewNoticeDisplay(
                id: "section-\(notice.id)",
                title: "\(notice.title) unavailable",
                message: notice.reason
            )
        }

        return warningEventSummaries.first.map { event in
            OverviewNoticeDisplay(
                id: "event-\(event.id)",
                title: event.reason,
                message: event.summary
            )
        }
    }

    private func makeNodeTab(from snapshot: ClusterSnapshot, sectionNotices: [SectionAvailabilityDisplay]) -> NodeTabDisplay {
        NodeTabDisplay(
            summary: snapshot.nodesSection.value.map { "\($0.ready)/\($0.total) nodes ready" } ?? "- nodes ready",
            unavailableMessage: tabUnavailableMessage(
                sectionID: SnapshotSectionName.nodes.rawValue,
                prefix: "Node data unavailable",
                sectionNotices: sectionNotices
            )
        )
    }

    private func makePodTab(
        from snapshot: ClusterSnapshot,
        visibleItems: [WatchItemDisplay],
        sectionNotices: [SectionAvailabilityDisplay]
    ) -> PodTabDisplay {
        PodTabDisplay(
            summary: snapshot.podsSection.value.map { "\($0.running)/\($0.total) pods running" } ?? "- pods running",
            rows: visibleItems,
            unavailableMessage: tabUnavailableMessage(
                sectionID: SnapshotSectionName.pods.rawValue,
                prefix: "Pod data unavailable",
                sectionNotices: sectionNotices
            )
        )
    }

    private func makeEventsTab(
        rows: [WarningEventDisplay],
        sectionNotices: [SectionAvailabilityDisplay]
    ) -> EventsTabDisplay {
        EventsTabDisplay(
            rows: rows,
            unavailableMessage: tabUnavailableMessage(
                sectionID: SnapshotSectionName.warningEvents.rawValue,
                prefix: "Warning events unavailable",
                sectionNotices: sectionNotices
            )
        )
    }

    private func tabUnavailableMessage(
        sectionID: String,
        prefix: String,
        sectionNotices: [SectionAvailabilityDisplay]
    ) -> String? {
        guard let notice = sectionNotices.first(where: { $0.id == sectionID }) else {
            return nil
        }

        return "\(prefix): \(notice.reason)"
    }

    private func sanitizedSectionReason(_ value: String) -> String {
        normalizedText(value) ?? "Section unavailable"
    }

    private func sortByAttention(_ items: [TrackedItemStatus]) -> [TrackedItemStatus] {
        items.sorted { left, right in
            if left.state.rawValue != right.state.rawValue {
                return left.state.rawValue > right.state.rawValue
            }

            return left.target.displayTitle < right.target.displayTitle
        }
    }

    private func makeDisplayItem(_ item: TrackedItemStatus, now: Date) -> WatchItemDisplay {
        WatchItemDisplay(
            id: item.target.displayTitle,
            title: item.target.displayTitle,
            state: item.state,
            reason: item.reason,
            detail: WatchItemDetailDisplay(
                stateLabel: item.state.label,
                reason: item.reason,
                affectedPodCount: item.affectedPodCount,
                examplePodNames: Array(item.examplePodNames.prefix(3)),
                latestWarning: item.latestWarning.map { makeWarningEventDisplay(from: $0, now: now) }
            )
        )
    }

    private func makeWarningEventSummaries(from warningEvents: [WarningEventRecord], now: Date) -> [WarningEventDisplay] {
        var groups: [WarningEventGroupKey: WarningEventGroup] = [:]

        for event in warningEvents {
            let key = WarningEventGroupKey(event: event)
            groups[key, default: WarningEventGroup(key: key, reason: event.reason)]
                .add(event, message: shortenedWarningMessage(event.message))
        }

        return groups.values
            .sorted { left, right in
                let leftDate = left.observedAt ?? .distantPast
                let rightDate = right.observedAt ?? .distantPast

                if leftDate != rightDate {
                    return leftDate > rightDate
                }

                if left.reason != right.reason {
                    return left.reason < right.reason
                }

                return warningLocation(namespace: left.key.namespace, objectKind: left.key.objectKind, objectName: left.key.objectName) <
                    warningLocation(namespace: right.key.namespace, objectKind: right.key.objectKind, objectName: right.key.objectName)
            }
            .prefix(warningEventSummaryLimit)
            .map { group in
                WarningEventDisplay(
                    id: group.key.id,
                    reason: group.reason,
                    location: warningLocation(
                        namespace: group.key.namespace,
                        objectKind: group.key.objectKind,
                        objectName: group.key.objectName
                    ),
                    age: warningAge(from: group.observedAt, to: now),
                    occurrenceCount: group.occurrenceCount,
                    message: group.message
                )
            }
    }

    private func makeWarningEventDisplay(from event: WarningEventRecord, now: Date) -> WarningEventDisplay {
        WarningEventDisplay(
            id: WarningEventGroupKey(event: event).id,
            reason: event.reason,
            location: warningLocation(
                namespace: event.namespace,
                objectKind: event.objectKind,
                objectName: event.objectName
            ),
            age: warningAge(from: event.observedAt, to: now),
            occurrenceCount: max(1, event.count),
            message: shortenedWarningMessage(event.message)
        )
    }

    private func warningLocation(namespace: String?, objectKind: String?, objectName: String?) -> String {
        let namespace = normalizedText(namespace)
        let objectKind = normalizedText(objectKind)
        let objectName = normalizedText(objectName)

        if let namespace, let objectKind, let objectName {
            return "\(namespace)/\(objectKind.lowercased())/\(objectName)"
        }

        if let namespace, let objectName {
            return "\(namespace)/\(objectName)"
        }

        if let objectName {
            return objectName
        }

        return "unknown object"
    }

    private func warningAge(from date: Date?, to now: Date) -> String {
        guard let date else {
            return "recently"
        }

        return relativeAge(from: date, to: now)
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

    private func primaryStatusReason(for state: ClusterHealthState, snapshot: ClusterSnapshot, visibleItems: [WatchItemDisplay], sectionNotices: [SectionAvailabilityDisplay], staleReason: String?) -> String {
        switch state {
        case .ok:
            return "Cluster looks healthy"
        case .bad:
            if let reason = visibleItems.first(where: { $0.state == .bad })?.reason {
                return reason
            }

            if let nodeDeficit = nodeDeficit(from: snapshot), nodeDeficit > 0 {
                return countLabel(nodeDeficit, singular: "node", plural: "nodes", suffix: "not ready")
            }

            if let podDeficit = podDeficit(from: snapshot), podDeficit > 0 {
                return countLabel(podDeficit, singular: "pod", plural: "pods", suffix: "not running")
            }

            return "Cluster needs attention"
        case .watch:
            if let reason = visibleItems.first(where: { $0.state == .watch })?.reason {
                return reason
            }

            if let sectionReason = sectionNotices.first?.reason {
                return sectionReason
            }

            if snapshot.warningEventCount > 0 {
                return countLabel(snapshot.warningEventCount, singular: "warning event", plural: "warning events")
            }

            if let podDeficit = podDeficit(from: snapshot), podDeficit > 0 {
                return countLabel(podDeficit, singular: "pod", plural: "pods", suffix: "not running")
            }

            return "Cluster has warnings"
        case .stale:
            return staleReason ?? "Last cluster status is stale"
        }
    }

    private func countLabel(_ count: Int, singular: String, plural: String, suffix: String? = nil) -> String {
        let noun = count == 1 ? singular : plural
        let suffixText = suffix.map { " \($0)" } ?? ""
        return "\(count) \(noun)\(suffixText)"
    }

    private func nodeDeficit(from snapshot: ClusterSnapshot) -> Int? {
        snapshot.nodesSection.value.map { max(0, $0.total - $0.ready) }
    }

    private func podDeficit(from snapshot: ClusterSnapshot) -> Int? {
        snapshot.podsSection.value.map { max(0, $0.total - $0.running) }
    }

    private func staleBanner(
        for state: ClusterHealthState,
        snapshot: ClusterSnapshot,
        failureReason: String?,
        now: Date
    ) -> StaleBannerDisplay? {
        guard state == .stale else {
            return nil
        }

        return StaleBannerDisplay(
            lastUpdated: relativeAge(from: snapshot.capturedAt, to: now),
            reason: failureReason ?? "Refresh failed"
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

    private func shortenedWarningMessage(_ value: String?) -> String? {
        guard let value = normalizedText(value) else {
            return nil
        }

        guard value.count > warningMessageLimit else {
            return value
        }

        return String(value.prefix(warningMessageLimit))
    }

    private func normalizedText(_ value: String?) -> String? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, !text.isEmpty else {
            return nil
        }

        return text
    }
}

private struct WarningEventGroupKey: Hashable, Sendable {
    let reason: String
    let objectKind: String?
    let namespace: String?
    let objectName: String?

    init(event: WarningEventRecord) {
        self.reason = event.reason
        self.objectKind = event.objectKind
        self.namespace = event.namespace
        self.objectName = event.objectName
    }

    var id: String {
        [reason, objectKind, namespace, objectName]
            .map { $0 ?? "-" }
            .joined(separator: "|")
    }
}

private struct WarningEventGroup: Sendable {
    let key: WarningEventGroupKey
    let reason: String
    private(set) var observedAt: Date?
    private(set) var occurrenceCount = 0
    private(set) var message: String?
    private var messageObservedAt: Date?

    init(key: WarningEventGroupKey, reason: String) {
        self.key = key
        self.reason = reason
    }

    mutating func add(_ event: WarningEventRecord, message: String?) {
        occurrenceCount += max(1, event.count)

        if let observedAt = event.observedAt {
            self.observedAt = max(self.observedAt ?? .distantPast, observedAt)
        }

        guard let message else {
            return
        }

        let eventObservedAt = event.observedAt ?? .distantPast
        if self.message == nil || eventObservedAt >= (messageObservedAt ?? .distantPast) {
            self.message = message
            self.messageObservedAt = eventObservedAt
        }
    }
}
