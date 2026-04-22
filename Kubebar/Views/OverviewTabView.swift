import SwiftUI
import KubebarCore

struct OverviewTabView: View {
    let display: MenuDisplayModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatusSummaryView(display: display)
            StaleBannerView(banner: display.staleBanner)
            CompactCountersView(counters: display.counters)
            WatchlistSectionView(display: display)

            if let notice = display.overviewNotice {
                OverviewNoticeView(notice: notice)
            }
        }
    }
}

private struct OverviewNoticeView: View {
    let notice: OverviewNoticeDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(notice.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(Text(notice.title))
                .accessibilityLabel(notice.title)

            Text(notice.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .help(Text(notice.message))
                .accessibilityLabel(notice.message)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notice.title), \(notice.message)")
        .focusable()
    }
}
