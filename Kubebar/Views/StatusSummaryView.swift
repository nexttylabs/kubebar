import SwiftUI
import KubebarCore

struct StatusSummaryView: View {
    let display: MenuDisplayModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(display.contextName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(display.state.label)
                    .font(.caption.weight(.semibold))
            }

            Text(display.healthSentence)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
