import SwiftUI
import KubebarCore

struct StatusSummaryView: View {
    let display: MenuDisplayModel

    private var presentation: MenuBarStatusPresentation {
        MenuBarStatusPresentation(state: display.state)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(display.contextName)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(Text(display.contextName))
                .accessibilityLabel(display.contextName)

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                Image(systemName: presentation.symbolName)
                Text(display.state.label)
                    .fontWeight(.semibold)
                Text(display.overview.statusText)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(.subheadline)
            .help(Text(display.overview.statusHelpText))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(display.overview.statusAccessibilityLabel)
        .focusable()
    }
}
