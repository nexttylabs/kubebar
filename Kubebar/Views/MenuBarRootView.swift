import SwiftUI
import KubebarCore

struct MenuBarRootView: View {
    let display: MenuDisplayModel
    let isShowingSetup: Bool
    let refreshCadence: RefreshCadence
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onPrepareSettings: () -> Void
    let onQuit: () -> Void
    let onSelectRefreshCadence: (RefreshCadence) -> Void
    @Environment(\.openSettings) private var openSettings
    @State private var selectedTab: MenuTab = .overview

    var body: some View {
        menuContent
    }

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            mainContent

            Divider()
            MenuFooterView(
                lastUpdated: display.lastUpdated,
                refreshCadence: refreshCadence,
                isRefreshing: isRefreshing,
                onRefresh: onRefresh,
                onOpenSettings: openSettingsFromMenu,
                onQuit: onQuit,
                onSelectRefreshCadence: onSelectRefreshCadence
            )
        }
        .frame(width: Layout.menuWidth)
        .padding(16)
        .onAppear {
            selectedTab = .overview
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch isShowingSetup {
        case true:
            ConfigurationRequiredView(onOpenSettings: openSettingsFromMenu)
                .frame(maxWidth: .infinity, alignment: .leading)
        case false:
            configuredMenuContent
        }
    }

    private var configuredMenuContent: some View {
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

    private func openSettingsFromMenu() {
        openSettings()
    }

    private enum Layout {
        static let menuWidth: CGFloat = 360
        static let maxContentHeight: CGFloat = 520
    }
}
