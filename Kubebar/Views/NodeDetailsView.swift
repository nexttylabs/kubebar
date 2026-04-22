import SwiftUI
import KubebarCore

struct NodeDetailsView: View {
    let display: NodeTabDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            summary

            if display.unavailableMessage == nil {
                if display.rows.isEmpty, display.summary.hasPrefix("0/0") || display.summary.hasPrefix("-") {
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

            HStack(spacing: 10) {
                resourceLabel(title: "CPU", value: row.cpuLabel)
                resourceLabel(title: "Memory", value: row.memoryLabel)
            }
        }
        .padding(row.readiness == .notReady ? 8 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if row.readiness == .notReady {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.08))
            }
        }
        .overlay {
            if row.readiness == .notReady {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.red.opacity(0.35), lineWidth: 1)
            }
        }
        .help(Text(row.helpText))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
        .focusable()
    }

    private var statusLabel: some View {
        HStack(spacing: 4) {
            if row.readiness == .notReady {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .accessibilityHidden(true)
            }

            Text(row.statusLabel)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(row.readiness == .notReady ? Color.red : Color.secondary)
        .lineLimit(1)
    }

    private func resourceLabel(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .monospacedDigit()
        }
        .font(.caption)
        .lineLimit(1)
    }
}
