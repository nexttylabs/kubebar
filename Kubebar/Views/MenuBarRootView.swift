import SwiftUI
import KubebarCore

struct MenuBarRootView: View {
    let display: MenuDisplayModel
    @Binding var setupState: SetupFlowState
    let isShowingSetup: Bool
    let onRefresh: () -> Void
    let onEditWatchlist: () -> Void
    let onCompleteSetup: () -> Void
    let onSelectContext: (String?) -> Void
    let onRetryTargets: () -> Void

    var body: some View {
        Group {
            if isShowingSetup {
                SetupView(
                    state: $setupState,
                    onComplete: onCompleteSetup,
                    onSelectContext: onSelectContext,
                    onRetryTargets: onRetryTargets
                )
                    .frame(
                        width: Layout.setupWidth,
                        height: Layout.setupHeight,
                        alignment: .topLeading
                    )
            } else {
                menuContent
            }
        }
    }

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatusSummaryView(display: display)
            StaleBannerView(banner: display.staleBanner)
            CompactCountersView(counters: display.counters)
            WatchlistSectionView(display: display)
            WarningEventsView(count: display.counters.warningEvents)
            NodeDetailsView(summary: display.counters.nodes)
            Divider()
            actions
        }
        .frame(width: 340)
        .padding(16)
    }

    private var actions: some View {
        HStack {
            Button("Retry now", action: onRefresh)
            Spacer()
            Button("Edit watchlist", action: onEditWatchlist)
        }
    }

    private enum Layout {
        static let setupWidth: CGFloat = 560
        static let setupHeight: CGFloat = 560
    }
}
