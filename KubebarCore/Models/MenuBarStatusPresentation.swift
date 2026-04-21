import Foundation

public struct MenuBarStatusPresentation: Equatable, Sendable {
    public let state: ClusterHealthState

    public init(state: ClusterHealthState) {
        self.state = state
    }

    public var symbolName: String {
        switch state {
        case .ok:
            "checkmark.circle"
        case .watch:
            "exclamationmark.triangle"
        case .bad:
            "xmark.octagon"
        case .stale:
            "clock.badge.exclamationmark"
        }
    }

    public var accessibilityLabel: String {
        "Kubebar \(state.label)"
    }
}
