enum MenuTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case nodes = "Nodes"
    case pods = "Pods"
    case events = "Events"

    var id: String {
        rawValue
    }

    var label: String {
        rawValue
    }

    var sfSymbol: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .nodes: return "server.rack"
        case .pods: return "cube.box.fill"
        case .events: return "exclamationmark.triangle.fill"
        }
    }
}
