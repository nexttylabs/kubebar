import Foundation

public enum RefreshCadence: Int, CaseIterable, Equatable, Hashable, Identifiable, Sendable {
    case thirtySeconds = 30
    case oneMinute = 60
    case twoMinutes = 120
    case fiveMinutes = 300

    public static let `default`: RefreshCadence = .oneMinute

    public var id: Int {
        seconds
    }

    public var seconds: Int {
        rawValue
    }

    public var label: String {
        switch self {
        case .thirtySeconds:
            "30 sec"
        case .oneMinute:
            "1 min"
        case .twoMinutes:
            "2 min"
        case .fiveMinutes:
            "5 min"
        }
    }

    public static func from(seconds: Int) -> RefreshCadence {
        RefreshCadence(rawValue: seconds) ?? .default
    }
}
