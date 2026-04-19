import Foundation

public enum WatchTarget: Codable, Equatable, Hashable, Sendable {
    case namespace(String)
    case workload(namespace: String, name: String)

    public var displayTitle: String {
        switch self {
        case let .namespace(name):
            name
        case let .workload(namespace, name):
            "\(namespace)/\(name)"
        }
    }
}

public struct TrackedItemStatus: Equatable, Sendable {
    public let target: WatchTarget
    public let state: ClusterHealthState
    public let reason: String

    public init(target: WatchTarget, state: ClusterHealthState, reason: String) {
        self.target = target
        self.state = state
        self.reason = reason
    }
}
