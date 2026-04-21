import SwiftUI
import KubebarCore

struct TrackedItemDetailView: View {
    let item: WatchItemDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("State: \(item.detail.stateLabel)")
            Text(item.detail.reason)

            if let affectedPodCount = item.detail.affectedPodCount {
                Text("Affected pods: \(affectedPodCount)")
            }

            if !item.detail.examplePodNames.isEmpty {
                Text("Examples: \(item.detail.examplePodNames.joined(separator: ", "))")
            }

            if let latestWarning = item.detail.latestWarning {
                Text("Latest warning: \(latestWarning.summary)")

                if let message = latestWarning.message {
                    Text(message)
                        .lineLimit(2)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.leading, 6)
    }
}
