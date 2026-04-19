import Foundation

public enum ClusterHealthState: Int, Codable, Sendable {
    case ok = 0
    case watch = 1
    case bad = 2
    case stale = 3

    public var label: String {
        switch self {
        case .ok:
            "OK"
        case .watch:
            "Watch"
        case .bad:
            "Bad"
        case .stale:
            "Stale"
        }
    }
}
