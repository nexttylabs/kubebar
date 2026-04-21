import SwiftUI
import KubebarCore

struct MenuBarRootView: View {
    let display: MenuDisplayModel
    @Binding var setupState: SetupFlowState
    let isShowingSetup: Bool
    let refreshCadence: RefreshCadence
    let onRefresh: () -> Void
    let onEditWatchlist: () -> Void
    let onCompleteSetup: () -> Void
    let onSelectContext: (String?) -> Void
    let onSelectRefreshCadence: (RefreshCadence) -> Void
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
            WarningEventsView(count: display.counters.warningEvents, summaries: display.warningEventSummaries, sectionNotices: display.sectionNotices)
            NodeDetailsView(summary: display.counters.nodes)
            Divider()
            refreshControls
            actions
        }
        .frame(width: 340)
        .padding(16)
    }

    private var refreshControls: some View {
        HStack(spacing: 8) {
            Text("Refresh")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Refresh cadence", selection: refreshCadenceBinding) {
                ForEach(RefreshCadence.allCases) { cadence in
                    Text(cadence.label).tag(cadence)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 96)

            Text("Last updated \(display.lastUpdated)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()
        }
    }

    private var actions: some View {
        HStack {
            Button("Retry now", action: onRefresh)
            Spacer()
            Button("Edit watchlist", action: onEditWatchlist)
        }
    }

    private var refreshCadenceBinding: Binding<RefreshCadence> {
        Binding(
            get: { refreshCadence },
            set: { onSelectRefreshCadence($0) }
        )
    }

    private enum Layout {
        static let setupWidth: CGFloat = 560
        static let setupHeight: CGFloat = 560
    }
}
