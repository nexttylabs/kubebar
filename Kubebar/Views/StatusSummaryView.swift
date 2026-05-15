import SwiftUI
import KubebarCore

struct StatusSummaryView: View {
    let display: MenuDisplayModel
    let k9sHandoffState: K9sHandoffLaunchState
    let onOpenK9sHandoff: (OverviewK9sHandoff) -> Void

    private var presentation: MenuBarStatusPresentation {
        MenuBarStatusPresentation(state: display.state)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(display.overview.statusAccessibilityLabel)
            }

            if let handoff = display.overview.k9sHandoff {
                let message = k9sHandoffState.feedbackMessage(for: handoff) ?? display.overview.statusHelpText
                VStack(alignment: .leading, spacing: 6) {
                    handoffStatusRow(text: message, for: handoff)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .focusable()
    }

    private func handoffStatusRow(text: String, for handoff: OverviewK9sHandoff) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
                .help(Text(text))

            Spacer(minLength: 0)
            openK9sButton(for: handoff)
        }
    }

    private func openK9sButton(for handoff: OverviewK9sHandoff) -> some View {
        Button {
            onOpenK9sHandoff(handoff)
        } label: {
            Image(systemName: "arrow.right")
                .font(.caption)
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .keyboardShortcut("k", modifiers: .command)
        .help(Text(handoff.helpText))
        .accessibilityLabel(handoff.accessibilityLabel)
        .accessibilityHint(Text(handoff.buttonLabel(for: k9sHandoffState)))
        .disabled(k9sHandoffState.blocksNewHandoff(for: handoff))
    }
}

extension OverviewK9sHandoff {
    func buttonLabel(for state: K9sHandoffLaunchState) -> String {
        if state.blocksNewHandoff(for: self) {
            return "Opening in k9s..."
        }

        return actionLabel
    }
}
