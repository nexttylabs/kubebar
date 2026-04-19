import SwiftUI
import KubebarCore

struct CompactCountersView: View {
    let counters: MenuCounters

    var body: some View {
        HStack(spacing: 16) {
            CounterView(label: "Nodes", value: counters.nodes)
            CounterView(label: "Pods", value: counters.pods)
            CounterView(label: "Events", value: counters.warningEvents)
        }
    }
}

private struct CounterView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
