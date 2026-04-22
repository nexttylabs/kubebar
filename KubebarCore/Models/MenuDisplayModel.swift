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
    public let fullMessage: String?
    public let isTracked: Bool

    public var summary: String {
        let base = "\(reason) \(location) \(age)"

        if occurrenceCount > 1 {
            return "\(base) \(repeatLabel)"
        }

        return base
    }

    public var repeatLabel: String {
        "x\(occurrenceCount)"
    }

    public var metadataLabel: String {
        if occurrenceCount > 1 {
            return "\(age) / \(repeatLabel)"
        }

        return age
    }

    public var secondaryText: String {
        guard let message else {
            return location
        }

        return "\(location) - \(message)"
    }

    public var helpText: String {
        guard let fullMessage else {
            return summary
        }

        return "\(summary), \(fullMessage)"
    }

    public var accessibilityLabel: String {
        var parts: [String] = []

        if isTracked {
            parts.append("Tracked object warning")
        } else {
            parts.append("Warning")
        }

        parts.append(reason)
        parts.append("object \(location)")
        parts.append(age)

        if occurrenceCount > 1 {
            parts.append("repeated \(occurrenceCount) times")
        }

        if let fullMessage {
            parts.append(fullMessage)
        }

        return parts.joined(separator: ", ")
    }

    public init(
        id: String,
        reason: String,
        location: String,
        age: String,
        occurrenceCount: Int,
        message: String?,
        fullMessage: String? = nil,
        isTracked: Bool = false
    ) {
        self.id = id
        self.reason = reason
        self.location = location
        self.age = age
        self.occurrenceCount = occurrenceCount
        self.message = message
        self.fullMessage = fullMessage ?? message
        self.isTracked = isTracked
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

    public var hasExpandedContent: Bool {
        affectedPodCount != nil || !examplePodNames.isEmpty || latestWarning != nil
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

public enum NodeItemReadiness: Equatable, Sendable {
    case ready
    case notReady
}

public struct NodeItemDisplay: Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let readiness: NodeItemReadiness
    public let statusLabel: String
    public let cpuLabel: String
    public let memoryLabel: String
    public let issueText: String?
    public let helpText: String
    public let accessibilityLabel: String

    public init(
        name: String,
        readiness: NodeItemReadiness,
        statusLabel: String,
        cpuLabel: String,
        memoryLabel: String,
        issueText: String? = nil,
        helpText: String,
        accessibilityLabel: String
    ) {
        self.id = name
        self.name = name
        self.readiness = readiness
        self.statusLabel = statusLabel
        self.cpuLabel = cpuLabel
        self.memoryLabel = memoryLabel
        self.issueText = issueText
        self.helpText = helpText
        self.accessibilityLabel = accessibilityLabel
    }
}

public struct NodeTabDisplay: Equatable, Sendable {
    public let summary: String
    public let rows: [NodeItemDisplay]
    public let unavailableMessage: String?
    public let emptyMessage: String

    public init(
        summary: String,
        rows: [NodeItemDisplay] = [],
        unavailableMessage: String? = nil,
        emptyMessage: String = "No node data yet. Refresh or check Settings."
    ) {
        self.summary = summary
        self.rows = rows
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

public enum OverviewCardState: Equatable, Sendable {
    case current
    case stale
    case unavailable
}

public struct OverviewCardDisplay: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let value: String
    public let detail: String
    public let systemImageName: String
    public let state: OverviewCardState
    public let accessibilityLabel: String

    public init(
        id: String,
        title: String,
        value: String,
        detail: String,
        systemImageName: String,
        state: OverviewCardState,
        accessibilityLabel: String
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.detail = detail
        self.systemImageName = systemImageName
        self.state = state
        self.accessibilityLabel = accessibilityLabel
    }
}

public struct OverviewDisplay: Equatable, Sendable {
    public let statusText: String
    public let statusAccessibilityLabel: String
    public let cards: [OverviewCardDisplay]
    public let recentWarnings: [WarningEventDisplay]
    public let recentWarningsOverflowCount: Int
    public let recentWarningsEmptyMessage: String
    public let recentWarningsUnavailableMessage: String?

    public init(
        statusText: String,
        statusAccessibilityLabel: String,
        cards: [OverviewCardDisplay],
        recentWarnings: [WarningEventDisplay],
        recentWarningsOverflowCount: Int,
        recentWarningsEmptyMessage: String,
        recentWarningsUnavailableMessage: String? = nil
    ) {
        self.statusText = statusText
        self.statusAccessibilityLabel = statusAccessibilityLabel
        self.cards = cards
        self.recentWarnings = recentWarnings
        self.recentWarningsOverflowCount = recentWarningsOverflowCount
        self.recentWarningsEmptyMessage = recentWarningsEmptyMessage
        self.recentWarningsUnavailableMessage = recentWarningsUnavailableMessage
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
    public let overview: OverviewDisplay
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
        overview: OverviewDisplay? = nil,
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
        self.overview = overview ?? Self.makeOverview(
            contextName: contextName,
            state: state,
            primaryStatusReason: self.primaryStatusReason,
            counters: counters,
            warningEventSummaries: warningEventSummaries
        )
        self.nodeTab = nodeTab ?? Self.makeNodeTab(counters: counters, sectionNotices: sectionNotices)
        self.podTab = podTab ?? Self.makePodTab(counters: counters, visibleWatchItems: visibleWatchItems, sectionNotices: sectionNotices)
        self.eventsTab = eventsTab ?? Self.makeEventsTab(
            counters: counters,
            warningEventSummaries: warningEventSummaries,
            sectionNotices: sectionNotices
        )
    }

    private static func makeOverview(
        contextName: String,
        state: ClusterHealthState,
        primaryStatusReason: String,
        counters: MenuCounters,
        warningEventSummaries: [WarningEventDisplay]
    ) -> OverviewDisplay {
        OverviewDisplay(
            statusText: primaryStatusReason,
            statusAccessibilityLabel: "\(state.label), \(primaryStatusReason), context \(contextName)",
            cards: [
                OverviewCardDisplay(
                    id: "nodes",
                    title: "Nodes",
                    value: counters.nodes,
                    detail: "ready",
                    systemImageName: "server.rack",
                    state: .current,
                    accessibilityLabel: "Nodes \(counters.nodes) ready"
                ),
                OverviewCardDisplay(
                    id: "pods",
                    title: "Pods",
                    value: counters.pods,
                    detail: "running",
                    systemImageName: "shippingbox",
                    state: .current,
                    accessibilityLabel: "Pods \(counters.pods) running"
                )
            ],
            recentWarnings: Array(warningEventSummaries.prefix(2)),
            recentWarningsOverflowCount: max(0, warningEventSummaries.count - 2),
            recentWarningsEmptyMessage: warningEventsEmptyMessage(count: counters.warningEvents)
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
                ?? unavailableMessage(for: "workloads", prefix: "Workloads unavailable", sectionNotices: sectionNotices)
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
        case "0":
            return "No current warning events"
        case "-":
            return "Warning event count unavailable"
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
