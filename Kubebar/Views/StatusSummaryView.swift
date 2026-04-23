import SwiftUI
import KubebarCore

struct StatusSummaryView: View {
    let display: MenuDisplayModel
    let k9sHandoffState: K9sHandoffLaunchState
    let onOpenK9sHandoff: () -> Void

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
            }

            if let handoff = display.overview.k9sHandoff {
                VStack(alignment: .leading, spacing: 6) {
                    Text(display.overview.statusHelpText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .help(Text(display.overview.statusHelpText))

                    if let statusMessage = k9sHandoffState.feedbackMessage(for: handoff) {
                        HStack(alignment: .center, spacing: 8) {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .help(Text(statusMessage))

                            openK9sButton(for: handoff)
                        }
                    } else {
                        openK9sButton(for: handoff)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Open watched target in k9s")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(display.overview.statusAccessibilityLabel)
        .focusable()
    }

    private func openK9sButton(for handoff: OverviewK9sHandoff) -> some View {
        Button(action: onOpenK9sHandoff) {
            Image(systemName: "arrow.up.right.square")
                .font(.caption)
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .keyboardShortcut("k", modifiers: .command)
        .help(Text(handoff.helpText))
        .accessibilityLabel(handoff.accessibilityLabel)
        .accessibilityHint(Text(handoff.buttonLabel(for: k9sHandoffState)))
        .disabled(k9sHandoffState.isOpeningForSameTarget(handoff))
    }
}

private extension K9sHandoffLaunchState {
    func isOpeningForSameTarget(_ handoff: OverviewK9sHandoff) -> Bool {
        switch self {
        case let .opening(target):
            target == handoff
        default:
            false
        }
    }

    func feedbackMessage(for handoff: OverviewK9sHandoff) -> String? {
        switch self {
        case .idle:
            nil
        case .opening(let target):
            target == handoff ? "Opening k9s..." : nil
        case .failed(let target, let message):
            target == handoff ? message : nil
        }
    }

}

private extension OverviewK9sHandoff {
    func buttonLabel(for state: K9sHandoffLaunchState) -> String {
        if state.isOpeningForSameTarget(self) {
            return "Opening in k9s..."
        }

        return actionLabel
    }
}
