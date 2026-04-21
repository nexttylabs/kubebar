import SwiftUI

struct NodeDetailsView: View {
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Node details")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("\(summary) nodes ready")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Node details, \(summary) nodes ready")
        .focusable()
    }
}
