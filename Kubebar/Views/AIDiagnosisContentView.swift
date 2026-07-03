import SwiftUI

/// Renders an AI diagnosis Markdown string as structured, glanceable sections
/// instead of a single wall of raw Markdown text.
///
/// The diagnosis is split on `##` headings into sections. Each section renders
/// as a titled card with a heading icon derived from the leading emoji (🔍
/// causes, 🛠️ fixes), followed by the section body as styled Markdown. Content
/// before the first heading is discarded — `AIDiagnosticResponseFormatter`
/// already strips reasoning traces, so any remaining preamble is model chatter.
struct AIDiagnosisContentView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(sections, id: \.id) { section in
                AIDiagnosisSectionView(section: section)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sections: [AIDiagnosisSection] {
        AIDiagnosisSectionParser.parse(markdown: markdown)
    }
}

private struct AIDiagnosisSectionView: View {
    let section: AIDiagnosisSection

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: section.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(section.tint)

                Text(section.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(section.tint)

                Spacer(minLength: 0)
            }

            if !section.body.isEmpty {
                Text(section.attributedBody)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(section.background, in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .combine)
    }
}

struct AIDiagnosisSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let icon: String
    let tint: Color
    let background: Color
}

enum AIDiagnosisSectionParser {
    static func parse(markdown: String) -> [AIDiagnosisSection] {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var sections: [AIDiagnosisSection] = []
        var currentTitle: String?
        var currentBody: [String] = []

        func flush() {
            guard let title = currentTitle else { return }
            let body = currentBody
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else { return }
            let style = AIDiagnosisSectionStyle(for: normalized)
            sections.append(
                AIDiagnosisSection(
                    title: normalized,
                    body: body,
                    icon: style.icon,
                    tint: style.tint,
                    background: style.background
                )
            )
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("##") {
                flush()
                currentTitle = String(trimmed.dropFirst(2))
                    .trimmingCharacters(in: .whitespaces)
                currentBody = []
            } else if currentTitle != nil {
                currentBody.append(line)
            }
        }

        flush()
        return sections
    }
}

private struct AIDiagnosisSectionStyle {
    let icon: String
    let tint: Color
    let background: Color

    init(for title: String) {
        let lowered = title.lowercased()

        if lowered.contains("possible cause") || lowered.contains("caus") {
            self.icon = "magnifyingglass"
            self.tint = .orange
            self.background = Color.orange.opacity(0.1)
        } else if lowered.contains("fix") || lowered.contains("action") || lowered.contains("next") || lowered.contains("remedi") {
            self.icon = "wrench.and.screwdriver"
            self.tint = .green
            self.background = Color.green.opacity(0.1)
        } else {
            self.icon = "doc.text"
            self.tint = .secondary
            self.background = Color.secondary.opacity(0.08)
        }
    }
}

private extension AIDiagnosisSection {
    var attributedBody: AttributedString {
        (try? AttributedString(markdown: body)) ?? AttributedString(body)
    }
}
