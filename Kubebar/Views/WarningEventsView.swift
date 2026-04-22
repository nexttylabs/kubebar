import SwiftUI
import KubebarCore

struct WarningEventsView: View {
    let count: String
    let summaries: [WarningEventDisplay]
    let sectionNotices: [SectionAvailabilityDisplay]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Warning events")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(sectionNotices) { notice in
                let noticeText = "\(notice.title) unavailable: \(notice.reason)"
                Text(noticeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(noticeText))
                    .accessibilityLabel(noticeText)
            }

            if summaries.isEmpty, let emptySummaryText {
                Text(emptySummaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(summaries) { summary in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary.summary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(Text(summary.summary))
                            .accessibilityLabel(summary.summary)

                        if let message = summary.message {
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
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .focusable()
    }

    private var emptySummaryText: String? {
        switch count {
        case "0":
            return "No current warning events"
        case "1":
            return "1 warning event needs review"
        case "-":
            return sectionNotices.isEmpty ? "Warning event count unavailable" : nil
        default:
            return "\(count) warning events need review"
        }
    }

    private var accessibilitySummary: String {
        var parts = ["Warning events"]
        parts += sectionNotices.map { "\($0.title) unavailable: \($0.reason)" }

        if summaries.isEmpty {
            if let emptySummaryText {
                parts.append(emptySummaryText)
            }
            return parts.joined(separator: ", ")
        }

        parts += summaries.map { summary in
            if let message = summary.message {
                return "\(summary.summary), \(message)"
            }
            return summary.summary
        }
        return parts.joined(separator: ", ")
    }
}
