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
    @State private var selectedTabContentHeight: CGFloat = 0

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
            .labelsHidden()
            .pickerStyle(.segmented)

            selectedTabContentContainer
        }
        .onChange(of: selectedTab) { _, _ in
            selectedTabContentHeight = 0
        }
    }

    @ViewBuilder
    private var selectedTabContentContainer: some View {
        if selectedTabContentHeight > Layout.maxContentHeight {
            ScrollView {
                measuredSelectedTabContent
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: Layout.maxContentHeight, alignment: .top)
        } else {
            measuredSelectedTabContent
        }
    }

    private var measuredSelectedTabContent: some View {
        selectedTabContent
            .id(selectedTab)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .onMeasuredHeight { height in
                guard height > 0, abs(selectedTabContentHeight - height) > 0.5 else { return }
                selectedTabContentHeight = height
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
        onPrepareSettings()
        openSettings()
        SettingsWindowPresenter.bringToFrontAfterOpening()
    }

    private enum Layout {
        static let menuWidth: CGFloat = 360
        static let maxContentHeight: CGFloat = 560
    }
}

private struct MeasuredHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let nextHeight = nextValue()
        if nextHeight > 0 {
            value = nextHeight
        }
    }
}

private extension View {
    func onMeasuredHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: MeasuredHeightPreferenceKey.self,
                    value: ceil(proxy.size.height)
                )
            }
        }
        .onPreferenceChange(MeasuredHeightPreferenceKey.self, perform: onChange)
    }
}
