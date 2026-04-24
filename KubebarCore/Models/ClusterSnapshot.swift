import Foundation

public struct NodeSummary: Equatable, Sendable {
    public let ready: Int
    public let total: Int

    public init(ready: Int, total: Int) {
        self.ready = ready
        self.total = total
    }
}

public struct NodeDetail: Equatable, Sendable {
    public let name: String
    public let isReady: Bool
    public let issueReason: String?
    public let issueMessage: String?
    public let cpuUsageNanocores: Int64?
    public let cpuAllocatableNanocores: Int64?
    public let memoryUsageBytes: Int64?
    public let memoryAllocatableBytes: Int64?

    public init(
        name: String,
        isReady: Bool,
        issueReason: String? = nil,
        issueMessage: String? = nil,
        cpuUsageNanocores: Int64? = nil,
        cpuAllocatableNanocores: Int64? = nil,
        memoryUsageBytes: Int64? = nil,
        memoryAllocatableBytes: Int64? = nil
    ) {
        self.name = name
        self.isReady = isReady
        self.issueReason = issueReason
        self.issueMessage = issueMessage
        self.cpuUsageNanocores = cpuUsageNanocores
        self.cpuAllocatableNanocores = cpuAllocatableNanocores
        self.memoryUsageBytes = memoryUsageBytes
        self.memoryAllocatableBytes = memoryAllocatableBytes
    }
}

public struct PodSummary: Equatable, Sendable {
    public let ready: Int
    public let running: Int
    public let total: Int

    public init(ready: Int? = nil, running: Int, total: Int) {
        self.ready = ready ?? running
        self.running = running
        self.total = total
    }
}

public struct PodResourceSummary: Equatable, Sendable {
    public let cpuUsageNanocores: Int64?
    public let cpuRequestNanocores: Int64?
    public let cpuLimitNanocores: Int64?
    public let memoryUsageBytes: Int64?
    public let memoryRequestBytes: Int64?
    public let memoryLimitBytes: Int64?
    public let resourceAvailabilityMessage: String?

    public init(
        cpuUsageNanocores: Int64? = nil,
        cpuRequestNanocores: Int64? = nil,
        cpuLimitNanocores: Int64? = nil,
        memoryUsageBytes: Int64? = nil,
        memoryRequestBytes: Int64? = nil,
        memoryLimitBytes: Int64? = nil,
        resourceAvailabilityMessage: String? = nil
    ) {
        self.cpuUsageNanocores = cpuUsageNanocores
        self.cpuRequestNanocores = cpuRequestNanocores
        self.cpuLimitNanocores = cpuLimitNanocores
        self.memoryUsageBytes = memoryUsageBytes
        self.memoryRequestBytes = memoryRequestBytes
        self.memoryLimitBytes = memoryLimitBytes
        self.resourceAvailabilityMessage = resourceAvailabilityMessage
    }
}

public struct PodDetail: Equatable, Sendable {
    public let namespace: String
    public let name: String
    public let phase: String?
    public let readyContainerCount: Int?
    public let totalContainerCount: Int?
    public let statusReason: String?
    public let statusMessage: String?
    public let waitingReason: String?
    public let waitingMessage: String?
    public let terminatedReason: String?
    public let terminatedMessage: String?
    public let notReadyConditionReason: String?
    public let notReadyConditionMessage: String?
    public let hasUnreadyContainer: Bool
    public let isFailed: Bool
    public let isPending: Bool
    public let isUnknown: Bool
    public let isNotReady: Bool
    public let resourceSummary: PodResourceSummary

    public init(
        namespace: String,
        name: String,
        phase: String? = nil,
        readyContainerCount: Int? = nil,
        totalContainerCount: Int? = nil,
        statusReason: String? = nil,
        statusMessage: String? = nil,
        waitingReason: String? = nil,
        waitingMessage: String? = nil,
        terminatedReason: String? = nil,
        terminatedMessage: String? = nil,
        notReadyConditionReason: String? = nil,
        notReadyConditionMessage: String? = nil,
        hasUnreadyContainer: Bool = false,
        isFailed: Bool = false,
        isPending: Bool = false,
        isUnknown: Bool = false,
        isNotReady: Bool = false,
        resourceSummary: PodResourceSummary = PodResourceSummary()
    ) {
        self.namespace = namespace
        self.name = name
        self.phase = phase
        self.readyContainerCount = readyContainerCount
        self.totalContainerCount = totalContainerCount
        self.statusReason = statusReason
        self.statusMessage = statusMessage
        self.waitingReason = waitingReason
        self.waitingMessage = waitingMessage
        self.terminatedReason = terminatedReason
        self.terminatedMessage = terminatedMessage
        self.notReadyConditionReason = notReadyConditionReason
        self.notReadyConditionMessage = notReadyConditionMessage
        self.hasUnreadyContainer = hasUnreadyContainer
        self.isFailed = isFailed
        self.isPending = isPending
        self.isUnknown = isUnknown
        self.isNotReady = isNotReady
        self.resourceSummary = resourceSummary
    }
}

public struct ClusterMetricsSummary: Equatable, Sendable {
    public let cpuUsageNanocores: Int64
    public let cpuAllocatableNanocores: Int64
    public let memoryUsageBytes: Int64
    public let memoryAllocatableBytes: Int64

    public init(
        cpuUsageNanocores: Int64,
        cpuAllocatableNanocores: Int64,
        memoryUsageBytes: Int64,
        memoryAllocatableBytes: Int64
    ) {
        self.cpuUsageNanocores = cpuUsageNanocores
        self.cpuAllocatableNanocores = cpuAllocatableNanocores
        self.memoryUsageBytes = memoryUsageBytes
        self.memoryAllocatableBytes = memoryAllocatableBytes
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
    public let nodeDetailsSection: SnapshotSection<[NodeDetail]>
    public let podsSection: SnapshotSection<PodSummary>
    public let podDetailsSection: SnapshotSection<[PodDetail]>
    public let metricsSection: SnapshotSection<ClusterMetricsSummary>
    public let warningEventsSection: SnapshotSection<[WarningEventRecord]>
    public let workloadsSection: SnapshotSection<[TrackedItemStatus]>
    public let sectionFailures: [SnapshotSectionFailure]
    public let hasCompletedWatchedPods: Bool

    public init(
        contextName: String,
        nodeSummary: NodeSummary,
        podSummary: PodSummary,
        warningEventCount: Int,
        trackedItems: [TrackedItemStatus],
        nodeDetailsSection: SnapshotSection<[NodeDetail]> = .available([]),
        podDetailsSection: SnapshotSection<[PodDetail]> = .available([]),
        metricsSection: SnapshotSection<ClusterMetricsSummary> = .unavailable(reason: "Metrics unavailable"),
        hasCompletedWatchedPods: Bool = false,
        capturedAt: Date
    ) {
        self.contextName = contextName
        self.nodeSummary = nodeSummary
        self.podSummary = podSummary
        self.warningEventCount = warningEventCount
        self.trackedItems = trackedItems
        self.capturedAt = capturedAt
        self.nodesSection = .available(nodeSummary)
        self.nodeDetailsSection = nodeDetailsSection
        self.podsSection = .available(podSummary)
        self.podDetailsSection = podDetailsSection
        self.metricsSection = metricsSection
        self.warningEventsSection = .available([])
        self.workloadsSection = .available(trackedItems)
        self.sectionFailures = []
        self.hasCompletedWatchedPods = hasCompletedWatchedPods
    }

    public init(
        contextName: String,
        nodesSection: SnapshotSection<NodeSummary>,
        nodeDetailsSection: SnapshotSection<[NodeDetail]>? = nil,
        podsSection: SnapshotSection<PodSummary>,
        podDetailsSection: SnapshotSection<[PodDetail]>? = nil,
        metricsSection: SnapshotSection<ClusterMetricsSummary> = .unavailable(reason: "Metrics unavailable"),
        warningEventsSection: SnapshotSection<[WarningEventRecord]>,
        workloadsSection: SnapshotSection<[TrackedItemStatus]>,
        hasCompletedWatchedPods: Bool = false,
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
        self.nodeDetailsSection = nodeDetailsSection ?? Self.makeNodeDetailsSection(from: nodesSection)
        self.podsSection = podsSection
        self.podDetailsSection = podDetailsSection ?? Self.makePodDetailsSection(from: podsSection)
        self.metricsSection = metricsSection
        self.warningEventsSection = warningEventsSection
        self.workloadsSection = workloadsSection
        self.sectionFailures = Self.makeSectionFailures(
            nodesSection: nodesSection,
            podsSection: podsSection,
            warningEventsSection: warningEventsSection,
            workloadsSection: workloadsSection
        )
        self.hasCompletedWatchedPods = hasCompletedWatchedPods
    }

    private static func makeNodeDetailsSection(from nodesSection: SnapshotSection<NodeSummary>) -> SnapshotSection<[NodeDetail]> {
        switch nodesSection {
        case .available:
            .available([])
        case let .unavailable(reason):
            .unavailable(reason: reason)
        }
    }

    private static func makePodDetailsSection(from podsSection: SnapshotSection<PodSummary>) -> SnapshotSection<[PodDetail]> {
        switch podsSection {
        case .available:
            .available([])
        case let .unavailable(reason):
            .unavailable(reason: reason)
        }
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
