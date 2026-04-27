import SwiftUI
import KubebarCore

struct NodeDetailsView: View {
    let display: NodeTabDisplay

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
            Text("Node readiness")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            readableText(display.unavailableMessage ?? display.summary)
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
