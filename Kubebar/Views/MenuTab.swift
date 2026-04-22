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
}
