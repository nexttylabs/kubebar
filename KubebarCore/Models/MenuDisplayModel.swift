import Foundation

public struct MenuCounters: Equatable, Sendable {
    public let nodes: String
    public let pods: String
    public let warningEvents: String
}

public struct WarningEventDisplay: Equatable, Sendable, Identifiable {
    public let id: String
    public let reason: String
    public let location: String
    public let age: String
    public let occurrenceCount: Int
    public let message: String?

    public var summary: String {
        if occurrenceCount > 1 {
            return "\(reason) x\(occurrenceCount) \(location) \(age)"
        }

        return "\(reason) \(location) \(age)"
    }

    public init(
        id: String,
        reason: String,
        location: String,
        age: String,
        occurrenceCount: Int,
        message: String?
    ) {
        self.id = id
        self.reason = reason
        self.location = location
        self.age = age
        self.occurrenceCount = occurrenceCount
        self.message = message
    }
}

public struct WatchItemDetailDisplay: Equatable, Sendable {
    public let stateLabel: String
    public let reason: String
    public let affectedPodCount: Int?
    public let examplePodNames: [String]
    public let latestWarning: WarningEventDisplay?

    public init(
        stateLabel: String,
        reason: String,
        affectedPodCount: Int? = nil,
        examplePodNames: [String] = [],
        latestWarning: WarningEventDisplay? = nil
    ) {
        self.stateLabel = stateLabel
        self.reason = reason
        self.affectedPodCount = affectedPodCount
        self.examplePodNames = examplePodNames
        self.latestWarning = latestWarning
    }
}

public struct SectionAvailabilityDisplay: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let reason: String

    public init(id: String, title: String, reason: String) {
        self.id = id
        self.title = title
        self.reason = reason
    }
}

public struct WatchItemDisplay: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let state: ClusterHealthState
    public let reason: String
    public let detail: WatchItemDetailDisplay

    public init(
        id: String,
        title: String,
        state: ClusterHealthState,
        reason: String,
        detail: WatchItemDetailDisplay? = nil
    ) {
        self.id = id
        self.title = title
        self.state = state
        self.reason = reason
        self.detail = detail ?? WatchItemDetailDisplay(stateLabel: state.label, reason: reason)
    }
}

public struct StaleBannerDisplay: Equatable, Sendable {
    public let lastUpdated: String
    public let reason: String
}

public struct OverviewNoticeDisplay: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let message: String

    public init(id: String, title: String, message: String) {
        self.id = id
        self.title = title
        self.message = message
    }
}

public struct NodeTabDisplay: Equatable, Sendable {
    public let summary: String
    public let unavailableMessage: String?
    public let emptyMessage: String

    public init(summary: String, unavailableMessage: String? = nil, emptyMessage: String = "No node data yet. Refresh or check Settings.") {
        self.summary = summary
        self.unavailableMessage = unavailableMessage
        self.emptyMessage = emptyMessage
    }
}

public struct PodTabDisplay: Equatable, Sendable {
    public let summary: String
    public let rows: [WatchItemDisplay]
    public let unavailableMessage: String?
    public let emptyMessage: String

    public init(
        summary: String,
        rows: [WatchItemDisplay] = [],
        unavailableMessage: String? = nil,
        emptyMessage: String = "No pod data yet. Refresh or check Settings."
    ) {
        self.summary = summary
        self.rows = rows
        self.unavailableMessage = unavailableMessage
        self.emptyMessage = emptyMessage
    }
}

public struct EventsTabDisplay: Equatable, Sendable {
    public let rows: [WarningEventDisplay]
    public let unavailableMessage: String?
    public let emptyMessage: String

    public init(
        rows: [WarningEventDisplay] = [],
        unavailableMessage: String? = nil,
        emptyMessage: String = "No current warning events"
    ) {
        self.rows = rows
        self.unavailableMessage = unavailableMessage
        self.emptyMessage = emptyMessage
    }
}

public struct MenuDisplayModel: Equatable, Sendable {
    public let state: ClusterHealthState
    public let contextName: String
    public let healthSentence: String
    public let primaryStatusReason: String
    public let lastUpdated: String
    public let counters: MenuCounters
    public let warningEventSummaries: [WarningEventDisplay]
    public let sectionNotices: [SectionAvailabilityDisplay]
    public let visibleWatchItems: [WatchItemDisplay]
    public let hiddenWatchItemCount: Int
    public let staleBanner: StaleBannerDisplay?
    public let overviewNotice: OverviewNoticeDisplay?
    public let nodeTab: NodeTabDisplay
    public let podTab: PodTabDisplay
    public let eventsTab: EventsTabDisplay

    public init(
        state: ClusterHealthState,
        contextName: String,
        healthSentence: String,
        primaryStatusReason: String? = nil,
        lastUpdated: String,
        counters: MenuCounters,
        visibleWatchItems: [WatchItemDisplay],
        hiddenWatchItemCount: Int,
        staleBanner: StaleBannerDisplay?,
        warningEventSummaries: [WarningEventDisplay] = [],
        sectionNotices: [SectionAvailabilityDisplay] = [],
        overviewNotice: OverviewNoticeDisplay? = nil,
        nodeTab: NodeTabDisplay? = nil,
        podTab: PodTabDisplay? = nil,
        eventsTab: EventsTabDisplay? = nil
    ) {
        self.state = state
        self.contextName = contextName
        self.healthSentence = healthSentence
        self.primaryStatusReason = primaryStatusReason ?? healthSentence
        self.lastUpdated = lastUpdated
        self.counters = counters
        self.warningEventSummaries = warningEventSummaries
        self.sectionNotices = sectionNotices
        self.visibleWatchItems = visibleWatchItems
        self.hiddenWatchItemCount = hiddenWatchItemCount
        self.staleBanner = staleBanner
        self.overviewNotice = overviewNotice ?? Self.makeOverviewNotice(sectionNotices: sectionNotices, warningEventSummaries: warningEventSummaries)
        self.nodeTab = nodeTab ?? Self.makeNodeTab(counters: counters, sectionNotices: sectionNotices)
        self.podTab = podTab ?? Self.makePodTab(counters: counters, visibleWatchItems: visibleWatchItems, sectionNotices: sectionNotices)
        self.eventsTab = eventsTab ?? Self.makeEventsTab(
            counters: counters,
            warningEventSummaries: warningEventSummaries,
            sectionNotices: sectionNotices
        )
    }

    private static func makeOverviewNotice(
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

    private static func makeNodeTab(counters: MenuCounters, sectionNotices: [SectionAvailabilityDisplay]) -> NodeTabDisplay {
        NodeTabDisplay(
            summary: "\(counters.nodes) nodes ready",
            unavailableMessage: unavailableMessage(for: "nodes", prefix: "Node data unavailable", sectionNotices: sectionNotices)
        )
    }

    private static func makePodTab(
        counters: MenuCounters,
        visibleWatchItems: [WatchItemDisplay],
        sectionNotices: [SectionAvailabilityDisplay]
    ) -> PodTabDisplay {
        PodTabDisplay(
            summary: "\(counters.pods) pods running",
            rows: visibleWatchItems,
            unavailableMessage: unavailableMessage(for: "pods", prefix: "Pod data unavailable", sectionNotices: sectionNotices)
        )
    }

    private static func makeEventsTab(
        counters: MenuCounters,
        warningEventSummaries: [WarningEventDisplay],
        sectionNotices: [SectionAvailabilityDisplay]
    ) -> EventsTabDisplay {
        EventsTabDisplay(
            rows: warningEventSummaries,
            unavailableMessage: unavailableMessage(
                for: "warningEvents",
                prefix: "Warning events unavailable",
                sectionNotices: sectionNotices
            ),
            emptyMessage: warningEventsEmptyMessage(count: counters.warningEvents)
        )
    }

    private static func warningEventsEmptyMessage(count: String) -> String {
        switch count {
        case "0", "-":
            return "No current warning events"
        case "1":
            return "1 warning event needs review"
        default:
            return "\(count) warning events need review"
        }
    }

    private static func unavailableMessage(
        for sectionID: String,
        prefix: String,
        sectionNotices: [SectionAvailabilityDisplay]
    ) -> String? {
        guard let notice = sectionNotices.first(where: { $0.id == sectionID }) else {
            return nil
        }

        return "\(prefix): \(notice.reason)"
    }
}
