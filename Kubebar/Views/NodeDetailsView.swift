import SwiftUI
import KubebarCore

struct NodeDetailsView: View {
    let display: NodeTabDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Node readiness")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let unavailableMessage = display.unavailableMessage {
                readableText(unavailableMessage)
            } else {
                readableText(display.summary)

                if display.summary.hasPrefix("0/0") || display.summary.hasPrefix("-") {
                    readableText(display.emptyMessage)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(display.unavailableMessage ?? display.summary)
        .focusable()
    }

    private func readableText(_ value: String) -> some View {
        Text(value)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .help(Text(value))
            .accessibilityLabel(value)
    }
}
