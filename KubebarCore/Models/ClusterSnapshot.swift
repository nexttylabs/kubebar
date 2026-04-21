import Foundation

public struct NodeSummary: Equatable, Sendable {
    public let ready: Int
    public let total: Int

    public init(ready: Int, total: Int) {
        self.ready = ready
        self.total = total
    }
}

public struct PodSummary: Equatable, Sendable {
    public let running: Int
    public let total: Int

    public init(running: Int, total: Int) {
        self.running = running
        self.total = total
    }
}

public enum SnapshotSection<Value: Equatable & Sendable>: Equatable, Sendable {
    case available(Value)
    case unavailable(reason: String)

    public var value: Value? {
        switch self {
        case let .available(value):
            value
        case .unavailable:
            nil
        }
    }

    public var unavailableReason: String? {
        switch self {
        case .available:
            nil
        case let .unavailable(reason):
            reason
        }
    }

    public var isAvailable: Bool {
        value != nil
    }
}

public enum SnapshotSectionName: String, Equatable, Sendable {
    case nodes
    case pods
    case warningEvents
    case workloads

    public var displayName: String {
        switch self {
        case .nodes:
            "Nodes"
        case .pods:
            "Pods"
        case .warningEvents:
            "Warning events"
        case .workloads:
            "Workloads"
        }
    }
}

public struct SnapshotSectionFailure: Equatable, Sendable {
    public let section: SnapshotSectionName
    public let reason: String

    public init(section: SnapshotSectionName, reason: String) {
        self.section = section
        self.reason = reason
    }
}

public struct WarningEventRecord: Equatable, Sendable {
    public let reason: String
    public let namespace: String?
    public let objectKind: String?
    public let objectName: String?
    public let message: String?
    public let observedAt: Date?
    public let count: Int

    public init(
        reason: String,
        namespace: String?,
        objectKind: String?,
        objectName: String?,
        message: String?,
        observedAt: Date?,
        count: Int
    ) {
        self.reason = reason
        self.namespace = namespace
        self.objectKind = objectKind
        self.objectName = objectName
        self.message = message
        self.observedAt = observedAt
        self.count = count
    }
}

public struct ClusterSnapshot: Equatable, Sendable {
    public let contextName: String
    public let nodeSummary: NodeSummary
    public let podSummary: PodSummary
    public let warningEventCount: Int
    public let trackedItems: [TrackedItemStatus]
    public let capturedAt: Date
    public let nodesSection: SnapshotSection<NodeSummary>
    public let podsSection: SnapshotSection<PodSummary>
    public let warningEventsSection: SnapshotSection<[WarningEventRecord]>
    public let workloadsSection: SnapshotSection<[TrackedItemStatus]>
    public let sectionFailures: [SnapshotSectionFailure]

    public init(
        contextName: String,
        nodeSummary: NodeSummary,
        podSummary: PodSummary,
        warningEventCount: Int,
        trackedItems: [TrackedItemStatus],
        capturedAt: Date
    ) {
        self.contextName = contextName
        self.nodeSummary = nodeSummary
        self.podSummary = podSummary
        self.warningEventCount = warningEventCount
        self.trackedItems = trackedItems
        self.capturedAt = capturedAt
        self.nodesSection = .available(nodeSummary)
        self.podsSection = .available(podSummary)
        self.warningEventsSection = .available([])
        self.workloadsSection = .available(trackedItems)
        self.sectionFailures = []
    }

    public init(
        contextName: String,
        nodesSection: SnapshotSection<NodeSummary>,
        podsSection: SnapshotSection<PodSummary>,
        warningEventsSection: SnapshotSection<[WarningEventRecord]>,
        workloadsSection: SnapshotSection<[TrackedItemStatus]>,
        capturedAt: Date
    ) {
        let nodeSummary = nodesSection.value ?? NodeSummary(ready: 0, total: 0)
        let podSummary = podsSection.value ?? PodSummary(running: 0, total: 0)
        let warningEventCount = warningEventsSection.value?.reduce(0) { total, record in
            total + max(1, record.count)
        } ?? 0
        let trackedItems = workloadsSection.value ?? []

        self.contextName = contextName
        self.nodeSummary = nodeSummary
        self.podSummary = podSummary
        self.warningEventCount = warningEventCount
        self.trackedItems = trackedItems
        self.capturedAt = capturedAt
        self.nodesSection = nodesSection
        self.podsSection = podsSection
        self.warningEventsSection = warningEventsSection
        self.workloadsSection = workloadsSection
        self.sectionFailures = Self.makeSectionFailures(
            nodesSection: nodesSection,
            podsSection: podsSection,
            warningEventsSection: warningEventsSection,
            workloadsSection: workloadsSection
        )
    }

    private static func makeSectionFailures(
        nodesSection: SnapshotSection<NodeSummary>,
        podsSection: SnapshotSection<PodSummary>,
        warningEventsSection: SnapshotSection<[WarningEventRecord]>,
        workloadsSection: SnapshotSection<[TrackedItemStatus]>
    ) -> [SnapshotSectionFailure] {
        [
            sectionFailure(.nodes, from: nodesSection),
            sectionFailure(.pods, from: podsSection),
            sectionFailure(.warningEvents, from: warningEventsSection),
            sectionFailure(.workloads, from: workloadsSection)
        ].compactMap { $0 }
    }

    private static func sectionFailure<Value>(
        _ section: SnapshotSectionName,
        from snapshotSection: SnapshotSection<Value>
    ) -> SnapshotSectionFailure? {
        guard let reason = snapshotSection.unavailableReason else {
            return nil
        }

        return SnapshotSectionFailure(section: section, reason: reason)
    }
}
