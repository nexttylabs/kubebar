import SwiftUI
import KubebarCore

struct WatchlistSectionView: View {
    let display: MenuDisplayModel
    let k9sHandoffState: K9sHandoffLaunchState
    let onOpenK9sHandoff: (OverviewK9sHandoff) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Watching")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if display.visibleWatchItems.isEmpty {
                Text("No tracked workloads yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(display.visibleWatchItems) { item in
                    watchlistRow(for: item)
                }
            }

            if display.hiddenWatchItemCount > 0 {
                Text("+\(display.hiddenWatchItemCount) more watched")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func watchlistRow(for item: WatchItemDisplay) -> some View {
        if item.detail.hasExpandedContent {
            DisclosureGroup(
                content: {
                    TrackedItemDetailView(item: item)
                },
                label: {
                    WatchlistRowView(
                        item: item,
                        k9sHandoffState: k9sHandoffState,
                        onOpenK9sHandoff: onOpenK9sHandoff
                    )
                }
            )
        } else {
            WatchlistRowView(
                item: item,
                k9sHandoffState: k9sHandoffState,
                onOpenK9sHandoff: onOpenK9sHandoff
            )
        }
    }
}

private struct WatchlistRowView: View {
    let item: WatchItemDisplay
    let k9sHandoffState: K9sHandoffLaunchState
    let onOpenK9sHandoff: (OverviewK9sHandoff) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(Text(item.title))
                        .accessibilityLabel(item.title)
                    Text(item.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .combine)
                .focusable()

                Spacer()

                Text(item.state.label)
                    .font(.caption.weight(.semibold))

                if let handoff = item.k9sHandoff {
                    openK9sButton(for: handoff)
                }
            }

            if let feedbackMessage {
                Text(feedbackMessage)
                    .font(.caption)
                    .foregroundStyle(feedbackColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(feedbackMessage))
            }
        }
        .accessibilityElement(children: .contain)
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
        item.k9sHandoff.flatMap(k9sHandoffState.feedbackMessage)
    }

    private var feedbackColor: Color {
        if case .failed = k9sHandoffState {
            return .red
        }

        return .secondary
    }
}
