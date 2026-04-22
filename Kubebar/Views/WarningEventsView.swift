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

        parts += display.rows.map(\.accessibilityLabel)
        return parts.joined(separator: ", ")
    }
}

struct WarningEventRowView: View {
    let row: WarningEventDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                if row.isTracked {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }

                Text(row.reason)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 6)

                Text(row.metadataLabel)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(row.secondaryText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .help(Text(row.helpText))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
        .focusable()
    }
}
