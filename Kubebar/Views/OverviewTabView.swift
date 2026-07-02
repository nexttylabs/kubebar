import SwiftUI
import KubebarCore

struct OverviewTabView: View {
    let display: MenuDisplayModel
    let eventDiagnosis: EventDiagnosisPresentation?
    let k9sHandoffState: K9sHandoffLaunchState
    let onOpenK9sHandoff: (OverviewK9sHandoff) -> Void
    let onDiagnoseWarningEvent: (WarningEventDiagnosticTarget) -> Void
    let onDismissWarningEventDiagnosis: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatusSummaryView(
                display: display,
                k9sHandoffState: k9sHandoffState,
                onOpenK9sHandoff: onOpenK9sHandoff
            )
            StaleBannerView(banner: display.staleBanner)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(display.overview.cards) { card in
                    OverviewCardView(card: card)
                }
            }

            RecentWarningsOverviewView(
                display: display.overview,
                eventDiagnosis: eventDiagnosis,
                onDiagnoseWarningEvent: onDiagnoseWarningEvent,
                onDismissWarningEventDiagnosis: onDismissWarningEventDiagnosis
            )
        }
    }
}

private struct OverviewCardView: View {
    let card: OverviewCardDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: card.systemImageName)
                    .foregroundStyle(iconStyle)
                    .frame(width: 14)

                Text(card.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(card.value)
                .font(.headline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(card.detail)
                .font(.caption)
                .foregroundStyle(detailStyle)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(Text(card.detail))
                
            if let progress = card.progress {
                InlineProgressBar(progress: progress)
                    .padding(.top, 2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderStyle, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.accessibilityLabel)
        .help(Text(card.accessibilityLabel))
        .focusable()
    }

    private var iconStyle: Color {
        switch card.state {
        case .current:
            return .accentColor
        case .stale:
            return .secondary
        case .unavailable:
            return .orange
        }
    }

    private var detailStyle: HierarchicalShapeStyle {
        switch card.state {
        case .current, .stale:
            return .secondary
        case .unavailable:
            return .tertiary
        }
    }

    private var borderStyle: Color {
        switch card.state {
        case .current:
            return .clear
        case .stale:
            return .secondary.opacity(0.25)
        case .unavailable:
            return .orange.opacity(0.35)
        }
    }
}

private struct RecentWarningsOverviewView: View {
    let display: OverviewDisplay
    let eventDiagnosis: EventDiagnosisPresentation?
    let onDiagnoseWarningEvent: (WarningEventDiagnosticTarget) -> Void
    let onDismissWarningEventDiagnosis: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("Recent Warnings", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)

                Spacer()

                if display.recentWarningsOverflowCount > 0 {
                    Text("+\(display.recentWarningsOverflowCount) in Events")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("\(display.recentWarningsOverflowCount) more warnings in Events")
                        .focusable()
                }
            }

            if let unavailableMessage = display.recentWarningsUnavailableMessage {
                readableText(unavailableMessage)
            } else if display.recentWarnings.isEmpty {
                readableText(display.recentWarningsEmptyMessage)
            } else {
                ForEach(display.recentWarnings) { row in
                    recentWarningRow(row)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
    }

    private func recentWarningRow(_ row: WarningEventDisplay) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                WarningEventRowView(row: row)

                if let target = row.diagnosticTarget {
                    Button {
                        onDiagnoseWarningEvent(target)
                    } label: {
                        Label("AI Diagnose warning", systemImage: "sparkles")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .disabled(eventDiagnosis?.target == target && eventDiagnosis?.state.isLoading == true)
                    .help(Text(aiDiagnosisHelp(for: row)))
                    .accessibilityLabel(aiDiagnosisHelp(for: row))
                }
            }

            if let eventDiagnosis, eventDiagnosis.target == row.diagnosticTarget {
                EventDiagnosisPanel(
                    diagnosis: eventDiagnosis,
                    onRetry: {
                        onDiagnoseWarningEvent(eventDiagnosis.target)
                    },
                    onDismiss: onDismissWarningEventDiagnosis
                )
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func aiDiagnosisHelp(for row: WarningEventDisplay) -> String {
        "AI Diagnose \(row.reason) warning for \(row.location)"
    }

    private func readableText(_ value: String) -> some View {
        Text(value)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .help(Text(value))
            .accessibilityLabel(value)
            .focusable()
    }

    private var accessibilitySummary: String {
        var parts = ["Recent Warnings"]

        if let unavailableMessage = display.recentWarningsUnavailableMessage {
            parts.append(unavailableMessage)
            return parts.joined(separator: ", ")
        }

        if display.recentWarnings.isEmpty {
            parts.append(display.recentWarningsEmptyMessage)
            return parts.joined(separator: ", ")
        }

        parts += display.recentWarnings.map(\.accessibilityLabel)

        if display.recentWarningsOverflowCount > 0 {
            parts.append("\(display.recentWarningsOverflowCount) more in Events")
        }

        return parts.joined(separator: ", ")
    }
}

private struct EventDiagnosisPanel: View {
    let diagnosis: EventDiagnosisPresentation
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Label("AI Diagnosis", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))

                    Spacer()

                    if diagnosis.state.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .help(Text("Dismiss AI diagnosis"))
                    .accessibilityLabel("Dismiss AI diagnosis")
                }

                Text("Manual action. Sends the latest 5 matching Warning Events to your configured AI Provider. Kubebar will not execute suggested commands.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                content
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var content: some View {
        switch diagnosis.state {
        case .idle:
            Text("Click the sparkles button to generate a transient diagnosis.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .loading:
            Text("Analyzing latest matching warning events...")
                .font(.caption)
                .foregroundStyle(.secondary)
        case let .failed(message):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button("Retry", action: onRetry)
                    .controlSize(.small)
            }
        case let .success(markdown):
            ScrollView {
                AIDiagnosisContentView(markdown: markdown)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 160)
        }
    }
}
