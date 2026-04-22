import SwiftUI
import KubebarCore

struct WatchlistSectionView: View {
    let display: MenuDisplayModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Watchlist")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if display.visibleWatchItems.isEmpty {
                Text("No tracked namespaces yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(display.visibleWatchItems) { item in
                    DisclosureGroup(
                        content: {
                            TrackedItemDetailView(item: item)
                        },
                        label: {
                            WatchlistRowView(item: item)
                        }
                    )
                }
            }

            if display.hiddenWatchItemCount > 0 {
                Text("View all tracked (\(display.hiddenWatchItemCount) more)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct WatchlistRowView: View {
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

            Text(item.state.label)
                .font(.caption.weight(.semibold))
        }
    }
}
