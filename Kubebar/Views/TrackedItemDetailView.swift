import SwiftUI
import KubebarCore

struct TrackedItemDetailView: View {
    let item: WatchItemDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("State: \(item.state.label)")
            Text(item.reason)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.leading, 6)
    }
}
