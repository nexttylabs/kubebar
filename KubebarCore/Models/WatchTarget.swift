import Foundation

public enum WatchTarget: Codable, Equatable, Hashable, Sendable {
    case namespace(String)
    case workload(namespace: String, name: String, kind: WorkloadKind = .deployment)

    public var displayTitle: String {
        switch self {
        case let .namespace(name):
            name
        case let .workload(namespace, name, _):
            "\(namespace)/\(name)"
        }
    }

    public var stableID: String {
        switch self {
        case let .namespace(name):
            "namespace:\(name)"
        case let .workload(namespace, name, kind):
            "workload:\(kind.rawValue):\(namespace):\(name)"
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TargetCodingKeys.self)

        if container.contains(.namespace) {
            let namespace = try container.nestedContainer(keyedBy: NamespaceCodingKeys.self, forKey: .namespace)
            self = .namespace(try namespace.decode(String.self, forKey: .value))
            return
        }

        let workload = try container.nestedContainer(keyedBy: WorkloadCodingKeys.self, forKey: .workload)
        let namespace = try workload.decode(String.self, forKey: .namespace)
        let name = try workload.decode(String.self, forKey: .name)
        let kind = try workload.decodeIfPresent(WorkloadKind.self, forKey: .kind) ?? .deployment
        self = .workload(namespace: namespace, name: name, kind: kind)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: TargetCodingKeys.self)

        switch self {
        case let .namespace(name):
            var namespace = container.nestedContainer(keyedBy: NamespaceCodingKeys.self, forKey: .namespace)
            try namespace.encode(name, forKey: .value)
        case let .workload(namespaceName, name, kind):
            var workload = container.nestedContainer(keyedBy: WorkloadCodingKeys.self, forKey: .workload)
            try workload.encode(namespaceName, forKey: .namespace)
            try workload.encode(name, forKey: .name)
            try workload.encode(kind, forKey: .kind)
        }
    }
}

private enum TargetCodingKeys: String, CodingKey {
    case namespace
    case workload
}

private enum NamespaceCodingKeys: String, CodingKey {
    case value = "_0"
}

private enum WorkloadCodingKeys: String, CodingKey {
    case namespace
    case name
    case kind
}

public struct TrackedItemStatus: Equatable, Sendable {
    public let target: WatchTarget
    public let state: ClusterHealthState
    public let reason: String
    public let affectedPodCount: Int?
    public let examplePodNames: [String]
    public let latestWarning: WarningEventRecord?

    public init(
        target: WatchTarget,
        state: ClusterHealthState,
        reason: String,
        affectedPodCount: Int? = nil,
        examplePodNames: [String] = [],
        latestWarning: WarningEventRecord? = nil
    ) {
        self.target = target
        self.state = state
        self.reason = reason
        self.affectedPodCount = affectedPodCount
        self.examplePodNames = examplePodNames
        self.latestWarning = latestWarning
    }
}
