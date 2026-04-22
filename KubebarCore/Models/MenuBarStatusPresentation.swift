import Foundation

public struct MenuBarStatusPresentation: Equatable, Sendable {
    public enum IconSource: Equatable, Sendable {
        case system(String)
        case custom(String)
    }

    public let state: ClusterHealthState

    public init(state: ClusterHealthState) {
        self.state = state
    }

    public var icon: IconSource {
        switch state {
        case .ok:
            .system("checkmark.circle")
        case .watch:
            .system("exclamationmark.triangle")
        case .bad:
            .system("xmark.octagon")
        case .stale:
            .system("clock.badge.exclamationmark")
        }
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
