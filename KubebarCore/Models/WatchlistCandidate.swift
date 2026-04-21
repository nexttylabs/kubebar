import Foundation

public struct WatchlistCandidates: Equatable, Sendable {
    public let namespaces: [String]
    public let workloads: [WatchlistCandidate]

    public init(namespaces: [String] = [], workloads: [WatchlistCandidate] = []) {
        self.namespaces = namespaces
        self.workloads = workloads
    }

    public var isEmpty: Bool {
        namespaces.isEmpty && workloads.isEmpty
    }
}

public struct WatchlistCandidate: Equatable, Hashable, Sendable {
    public let target: WatchTarget
    public let namespace: String
    public let kind: WorkloadKind?
    public let name: String

    public init(target: WatchTarget, namespace: String, kind: WorkloadKind?, name: String) {
        self.target = target
        self.namespace = namespace
        self.kind = kind
        self.name = name
    }

    public static func namespace(_ namespace: String) -> WatchlistCandidate {
        WatchlistCandidate(
            target: .namespace(namespace),
            namespace: namespace,
            kind: nil,
            name: namespace
        )
    }

    public static func workload(namespace: String, name: String, kind: WorkloadKind) -> WatchlistCandidate {
        WatchlistCandidate(
            target: .workload(namespace: namespace, name: name, kind: kind),
            namespace: namespace,
            kind: kind,
            name: name
        )
    }

    public var displayTitle: String {
        guard let kind else {
            return namespace
        }

        return "\(kind.displayName) \(name)"
    }
}
