import SwiftUI
import KubebarCore

struct WarningEventsView: View {
    let display: EventsTabDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Warning events")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let unavailableMessage = display.unavailableMessage {
                readableText(unavailableMessage)
            } else if display.rows.isEmpty {
                readableText(display.emptyMessage)
            } else {
                ForEach(display.rows) { row in
                    WarningEventRowView(row: row)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
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

    private var accessibilitySummary: String {
        var parts = ["Warning events"]

        if let unavailableMessage = display.unavailableMessage {
            parts.append(unavailableMessage)
            return parts.joined(separator: ", ")
        }

        if display.rows.isEmpty {
            parts.append(display.emptyMessage)
            return parts.joined(separator: ", ")
        }

        parts += display.rows.map { row in
            if let message = row.message {
                return "\(row.summary), \(message)"
            }
            return row.summary
        }
        return parts.joined(separator: ", ")
    }
}

private struct WarningEventRowView: View {
    let row: WarningEventDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(row.summary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(Text(row.summary))
                .accessibilityLabel(row.summary)

            if let message = row.message {
                Text(message)
                    .lineLimit(2)
                    .help(Text(message))
                    .accessibilityLabel(message)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
