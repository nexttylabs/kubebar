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

public struct ClusterSnapshot: Equatable, Sendable {
    public let contextName: String
    public let nodeSummary: NodeSummary
    public let podSummary: PodSummary
    public let warningEventCount: Int
    public let trackedItems: [TrackedItemStatus]
    public let capturedAt: Date

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
    }
}
