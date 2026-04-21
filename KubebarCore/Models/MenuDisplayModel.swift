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

public struct MenuDisplayModel: Equatable, Sendable {
    public let state: ClusterHealthState
    public let contextName: String
    public let healthSentence: String
    public let lastUpdated: String
    public let counters: MenuCounters
    public let warningEventSummaries: [WarningEventDisplay]
    public let sectionNotices: [SectionAvailabilityDisplay]
    public let visibleWatchItems: [WatchItemDisplay]
    public let hiddenWatchItemCount: Int
    public let staleBanner: StaleBannerDisplay?

    public init(
        state: ClusterHealthState,
        contextName: String,
        healthSentence: String,
        lastUpdated: String,
        counters: MenuCounters,
        visibleWatchItems: [WatchItemDisplay],
        hiddenWatchItemCount: Int,
        staleBanner: StaleBannerDisplay?,
        warningEventSummaries: [WarningEventDisplay] = [],
        sectionNotices: [SectionAvailabilityDisplay] = []
    ) {
        self.state = state
        self.contextName = contextName
        self.healthSentence = healthSentence
        self.lastUpdated = lastUpdated
        self.counters = counters
        self.warningEventSummaries = warningEventSummaries
        self.sectionNotices = sectionNotices
        self.visibleWatchItems = visibleWatchItems
        self.hiddenWatchItemCount = hiddenWatchItemCount
        self.staleBanner = staleBanner
    }
}
