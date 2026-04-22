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
                let examples = "Examples: \(item.detail.examplePodNames.joined(separator: ", "))"
                Text(examples)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(examples))
                    .accessibilityLabel(examples)
            }

            if let latestWarning = item.detail.latestWarning {
                let latestWarningSummary = "Latest warning: \(latestWarning.summary)"
                Text(latestWarningSummary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(latestWarningSummary))
                    .accessibilityLabel(latestWarningSummary)

                if let message = latestWarning.message {
                    Text(message)
                        .lineLimit(2)
                        .help(Text(message))
                        .accessibilityLabel(message)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.leading, 6)
    }
}
