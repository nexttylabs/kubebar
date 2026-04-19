import Foundation

public struct MenuBarStatusPresentation: Equatable, Sendable {
    public let state: ClusterHealthState

    public init(state: ClusterHealthState) {
        self.state = state
    }

    public var symbolName: String {
        switch state {
        case .ok:
            "circle"
        case .watch:
            "exclamationmark.circle"
        case .bad:
            "xmark.octagon"
        case .stale:
            "clock"
        }
    }

    public var accessibilityLabel: String {
        "Kubebar \(state.label)"
    }
}
