import SwiftUI
import KubebarCore

struct StatusSummaryView: View {
    let display: MenuDisplayModel

    private var presentation: MenuBarStatusPresentation {
        MenuBarStatusPresentation(state: display.state)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(display.contextName)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(Text(display.contextName))
                .accessibilityLabel(display.contextName)

            HStack(spacing: 6) {
                Image(systemName: presentation.symbolName)
                Text(display.state.label)
                    .fontWeight(.semibold)
                Text(display.primaryStatusReason)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .font(.subheadline)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(presentation.accessibilityLabel), \(display.primaryStatusReason), context \(display.contextName)")
    }
}
