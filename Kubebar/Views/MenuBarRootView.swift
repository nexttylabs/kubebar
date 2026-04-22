import SwiftUI
import KubebarCore

struct MenuBarRootView: View {
    let display: MenuDisplayModel
    @Binding var setupState: SetupFlowState
    let isShowingSetup: Bool
    let refreshCadence: RefreshCadence
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onEditWatchlist: () -> Void
    let onCompleteSetup: () -> Void
    let onSelectContext: (String?) -> Void
    let onSelectRefreshCadence: (RefreshCadence) -> Void
    let onRetryTargets: () -> Void
    @State private var selectedTab: MenuTab = .overview

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
        VStack(alignment: .leading, spacing: 16) {
            Picker("Menu section", selection: $selectedTab) {
                ForEach(MenuTab.allCases) { tab in
                    Text(tab.label)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)

            ScrollView {
                selectedTabContent
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: Layout.maxContentHeight, alignment: .top)

            Divider()
            refreshControls
            actions
        }
        .frame(width: Layout.menuWidth)
        .padding(16)
        .onAppear {
            selectedTab = .overview
        }
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .overview:
            OverviewTabView(display: display)
        case .nodes:
            NodesTabView(display: display)
        case .pods:
            PodsTabView(display: display)
        case .events:
            EventsTabView(display: display)
        }
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
                .keyboardShortcut("r", modifiers: .command)
                .help(Text(isRefreshing ? "Refresh in progress" : "Refresh now"))
                .disabled(isRefreshing)
            Spacer()
            Button("Edit watchlist", action: onEditWatchlist)
                .keyboardShortcut("e", modifiers: .command)
                .help(Text("Edit watchlist"))
        }
    }

    private var refreshCadenceBinding: Binding<RefreshCadence> {
        Binding(
            get: { refreshCadence },
            set: { onSelectRefreshCadence($0) }
        )
    }

    private enum Layout {
        static let menuWidth: CGFloat = 360
        static let maxContentHeight: CGFloat = 520
        static let setupWidth: CGFloat = 560
        static let setupHeight: CGFloat = 560
    }
}
