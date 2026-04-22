import SwiftUI
import KubebarCore

struct PodsTabView: View {
    let display: MenuDisplayModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StaleBannerView(banner: display.staleBanner)
            podSummary
            podRows
        }
    }

    private var podSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pod readiness")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let unavailableMessage = display.podTab.unavailableMessage {
                readableText(unavailableMessage)
            } else {
                readableText(display.podTab.summary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(display.podTab.unavailableMessage ?? display.podTab.summary)
        .focusable()
    }

    @ViewBuilder
    private var podRows: some View {
        if display.podTab.unavailableMessage == nil {
            if display.podTab.rows.isEmpty {
                readableText(display.podTab.emptyMessage)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(display.podTab.rows) { item in
                        DisclosureGroup(
                            content: {
                                TrackedItemDetailView(item: item)
                            },
                            label: {
                                PodRowView(item: item)
                            }
                        )
                    }
                }
            }
        }
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

private struct PodRowView: View {
    let item: WatchItemDisplay

    var body: some View {
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

            Spacer()

            Text(item.detail.stateLabel)
                .font(.caption.weight(.semibold))
        }
    }
}
