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

            if summaries.isEmpty {
                Text(count == "0" ? "No current warning events" : "\(count) warning events need review")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .focusable()
    }

    private var accessibilitySummary: String {
        if !sectionNotices.isEmpty {
            let notices = sectionNotices.map { "\($0.title) unavailable: \($0.reason)" }
            return (["Warning events"] + notices).joined(separator: ", ")
        }

        if summaries.isEmpty {
            let text = count == "0" ? "No current warning events" : "\(count) warning events need review"
            return "Warning events, \(text)"
        }

        let rows = summaries.map { summary in
            if let message = summary.message {
                return "\(summary.summary), \(message)"
            }
            return summary.summary
        }
        return (["Warning events"] + rows).joined(separator: ", ")
    }
}
