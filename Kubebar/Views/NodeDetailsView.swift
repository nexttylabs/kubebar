import SwiftUI
import KubebarCore

struct NodeDetailsView: View {
    let display: NodeTabDisplay
    let k9sHandoffState: K9sHandoffLaunchState
    let onOpenK9sHandoff: (OverviewK9sHandoff) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            summary

            if display.unavailableMessage == nil {
                if display.showsEmptyMessage {
                    readableText(display.emptyMessage)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(display.rows) { row in
                            NodeRowView(row: row)
                        }
                    }
                }
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Node readiness")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                if let handoff = display.k9sHandoff {
                    openK9sButton(for: handoff)
                }
            }

            readableText(display.unavailableMessage ?? display.summary)

            if let feedbackMessage {
                Text(feedbackMessage)
                    .font(.caption)
                    .foregroundStyle(feedbackColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(feedbackMessage))
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

    private func openK9sButton(for handoff: OverviewK9sHandoff) -> some View {
        Button {
            onOpenK9sHandoff(handoff)
        } label: {
            Image(systemName: "arrow.right")
                .font(.caption)
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .help(Text(handoff.helpText))
        .accessibilityLabel(handoff.accessibilityLabel)
        .accessibilityHint(Text(handoff.buttonLabel(for: k9sHandoffState)))
        .disabled(k9sHandoffState.blocksNewHandoff(for: handoff))
    }

    private var feedbackMessage: String? {
        display.k9sHandoff.flatMap(k9sHandoffState.feedbackMessage)
    }

    private var feedbackColor: Color {
        if case .failed = k9sHandoffState {
            return .red
        }

        return .secondary
    }
}

private struct NodeRowView: View {
    let row: NodeItemDisplay

    private enum Style {
        static let errorPadding: CGFloat = 8
        static let errorCornerRadius: CGFloat = 8
        static let errorBackgroundOpacity = 0.08
        static let errorBorderOpacity = 0.35
    }

    private var isErrorState: Bool {
        row.readiness == .notReady
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            nodeContent
        }
        .padding(isErrorState ? Style.errorPadding : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if isErrorState {
                RoundedRectangle(cornerRadius: Style.errorCornerRadius)
                    .fill(Color.red.opacity(Style.errorBackgroundOpacity))
            }
        }
        .overlay {
            if isErrorState {
                RoundedRectangle(cornerRadius: Style.errorCornerRadius)
                    .strokeBorder(Color.red.opacity(Style.errorBorderOpacity), lineWidth: 1)
            }
        }
        .help(Text(row.helpText))
        .accessibilityElement(children: .contain)
    }

    private var nodeContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(row.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(row.name))

                Spacer(minLength: 8)

                statusLabel
            }

            if let issueText = row.issueText {
                Text(issueText)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(issueText))
            }

            HStack(spacing: 12) {
                resourceLabel(title: "CPU", value: row.cpuLabel, progress: row.cpuProgress)
                resourceLabel(title: "Memory", value: row.memoryLabel, progress: row.memoryProgress)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
        .focusable()
    }

    private var statusLabel: some View {
        HStack(spacing: 4) {
            if isErrorState {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .accessibilityHidden(true)
            }

            Text(row.statusLabel)
                .font(.caption.weight(.bold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(isErrorState ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
        )
        .foregroundStyle(isErrorState ? Color.red : Color.green)
        .lineLimit(1)
    }

    private func resourceLabel(title: String, value: String, progress: Double?) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .monospacedDigit()
            
            if let progress {
                InlineProgressBar(progress: progress)
                    .frame(width: 32)
                    .padding(.leading, 2)
            }
        }
        .font(.caption)
        .lineLimit(1)
    }
}
