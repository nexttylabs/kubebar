import Foundation

public struct WatchlistSelectionState: Equatable, Sendable {
    public var availableNamespaces: [String]
    public var availableWorkloads: [WatchlistCandidate]
    public var selectedTargets: Set<WatchTarget>

    public init(
        availableNamespaces: [String] = [],
        availableWorkloads: [WatchlistCandidate] = [],
        selectedTargets: Set<WatchTarget> = []
    ) {
        self.availableNamespaces = availableNamespaces
        self.availableWorkloads = availableWorkloads
        self.selectedTargets = selectedTargets
    }

    public var isEmpty: Bool {
        selectedTargets.isEmpty
    }

    public var selectedCount: Int {
        selectedTargets.count
    }

    public var hasAvailableTargets: Bool {
        !availableNamespaces.isEmpty || !availableWorkloads.isEmpty
    }

    public var emptyStateTitle: String {
        hasAvailableTargets ? "No watch targets selected" : "No watch targets available"
    }

    public var emptyStateMessage: String {
        if hasAvailableTargets {
            "Choose namespaces or workloads to keep Kubebar focused on the first screen."
        } else {
            "Choose a cluster context or retry loading watch targets."
        }
    }

    public var selectionSummary: String {
        selectedCount == 1 ? "1 target selected" : "\(selectedCount) targets selected"
    }

    public func isSelected(_ target: WatchTarget) -> Bool {
        selectedTargets.contains(target)
    }

    public mutating func setSelected(_ target: WatchTarget, to isSelected: Bool) {
        if isSelected {
            selectedTargets.insert(target)
        } else {
            selectedTargets.remove(target)
        }
    }

    public mutating func toggleNamespace(_ namespace: String) {
        toggle(.namespace(namespace))
    }

    public mutating func toggleWorkload(namespace: String, name: String, kind: WorkloadKind = .deployment) {
        toggle(.workload(namespace: namespace, name: name, kind: kind))
    }

    public mutating func toggle(_ target: WatchTarget) {
        if selectedTargets.contains(target) {
            selectedTargets.remove(target)
        } else {
            selectedTargets.insert(target)
        }
    }

    public mutating func replaceAvailableTargets(_ candidates: WatchlistCandidates) {
        availableNamespaces = candidates.namespaces
        availableWorkloads = candidates.workloads
    }

    public mutating func clearAvailableTargets() {
        availableNamespaces = []
        availableWorkloads = []
    }
}
