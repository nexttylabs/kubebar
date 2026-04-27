import AppKit
import SwiftUI
import KubebarCore

struct MenuBarRootView: View {
    let display: MenuDisplayModel
    let isShowingSetup: Bool
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onPrepareSettings: () -> Void
    let k9sHandoffState: K9sHandoffLaunchState
    let onOpenK9sHandoff: () -> Void
    let onQuit: () -> Void
    @Environment(\.openSettings) private var openSettings
    @State private var selectedTab: MenuTab = .overview
    @State private var selectedTabContentHeight: CGFloat = 0
    @State private var screenVisibleHeight = Layout.defaultScreenVisibleHeight

    var body: some View {
        menuContent
    }

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            mainContent
                .frame(maxWidth: .infinity, alignment: .topLeading)

            Divider()
            MenuFooterView(
                lastUpdated: display.lastUpdated,
                isRefreshing: isRefreshing,
                onRefresh: onRefresh,
                onOpenSettings: openSettingsFromMenu,
                onQuit: onQuit
            )
        }
        .frame(width: Layout.menuWidth)
        .padding(16)
        .background(VisibleScreenHeightReader(onChange: updateScreenVisibleHeight))
        .onAppear {
            selectedTab = .overview
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch isShowingSetup {
        case true:
            ConfigurationRequiredView(onOpenSettings: openSettingsFromMenu)
                .frame(
                    maxWidth: .infinity,
                    minHeight: Layout.minimumMainContentHeight,
                    alignment: .topLeading
                )
        case false:
            configuredMenuContent
        }
    }

    private var configuredMenuContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            tabPicker
            selectedTabContentContainer
            shortSelectedTabContentSpacer
        }
        .onChange(of: selectedTab) { _, _ in
            selectedTabContentHeight = 0
        }
    }

    private var tabPicker: some View {
        Picker("Menu section", selection: $selectedTab) {
            ForEach(MenuTab.allCases) { tab in
                Label(tab.label, systemImage: tab.sfSymbol)
                    .tag(tab)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var selectedTabContentContainer: some View {
        let maxContentHeight = selectedTabMaxContentHeight

        if selectedTabContentHeight > maxContentHeight {
            ScrollView {
                measuredSelectedTabContent
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: maxContentHeight, alignment: .top)
        } else {
            measuredSelectedTabContent
        }
    }

    @ViewBuilder
    private var shortSelectedTabContentSpacer: some View {
        let height = selectedTabContentFillerHeight

        if height > 0 {
            Color.clear
                .frame(height: height)
                .accessibilityHidden(true)
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
            OverviewTabView(
                display: display,
                k9sHandoffState: k9sHandoffState,
                onOpenK9sHandoff: onOpenK9sHandoff
            )
        case .nodes:
            NodesTabView(display: display)
        case .pods:
            PodsTabView(display: display, itemsMaxHeight: podItemsMaxHeight)
        case .events:
            EventsTabView(display: display)
        }
    }

    private var menuMaxHeight: CGFloat {
        Layout.menuMaxHeight(forScreenVisibleHeight: screenVisibleHeight)
    }

    private var selectedTabMaxContentHeight: CGFloat {
        Layout.selectedTabMaxContentHeight(forMenuMaxHeight: menuMaxHeight)
    }

    private var podItemsMaxHeight: CGFloat {
        Layout.podItemsMaxHeight(forSelectedTabContentHeight: selectedTabMaxContentHeight)
    }

    private var selectedTabContentFillerHeight: CGFloat {
        guard selectedTabContentHeight > 0 else { return 0 }

        return Layout.shortContentFillerHeight(
            forContentHeight: min(selectedTabContentHeight, selectedTabMaxContentHeight)
        )
    }

    private func openSettingsFromMenu() {
        onPrepareSettings()
        openSettings()
        SettingsWindowPresenter.bringToFrontAfterOpening()
    }

    private func updateScreenVisibleHeight(_ height: CGFloat) {
        guard let nextHeight = ScreenVisibleHeightUpdate.nextHeight(
            current: screenVisibleHeight,
            proposed: height,
            tolerance: Layout.heightTolerance
        ) else {
            return
        }

        Task { @MainActor in
            screenVisibleHeight = nextHeight
        }
    }

    private enum Layout {
        static let menuWidth: CGFloat = 360
        static let maximumSelectedTabContentHeight: CGFloat = 560
        static let minimumMenuHeight: CGFloat = 220
        static let minimumMainContentHeight: CGFloat = 280
        static let defaultScreenVisibleHeight: CGFloat = 900
        static let screenEdgeInset: CGFloat = 48
        static let nonTabContentHeightBudget: CGFloat = 170
        static let podTabNonItemContentHeightBudget: CGFloat = 110
        static let minimumPodItemsHeight: CGFloat = 160
        static let heightTolerance: CGFloat = 1

        static func menuMaxHeight(forScreenVisibleHeight visibleHeight: CGFloat) -> CGFloat {
            MenuLayoutSizing.maximumMenuHeight(
                forScreenVisibleHeight: visibleHeight,
                minimumHeight: minimumMenuHeight,
                screenEdgeInset: screenEdgeInset
            )
        }

        static func selectedTabMaxContentHeight(forMenuMaxHeight menuMaxHeight: CGFloat) -> CGFloat {
            MenuLayoutSizing.contentHeight(
                forMenuHeight: menuMaxHeight,
                reservedHeight: nonTabContentHeightBudget,
                preferredHeight: maximumSelectedTabContentHeight
            )
        }

        static func podItemsMaxHeight(forSelectedTabContentHeight contentHeight: CGFloat) -> CGFloat {
            max(minimumPodItemsHeight, contentHeight - podTabNonItemContentHeightBudget)
        }

        static func shortContentFillerHeight(forContentHeight contentHeight: CGFloat) -> CGFloat {
            MenuLayoutSizing.fillerHeight(
                forContentHeight: contentHeight,
                minimumHeight: minimumMainContentHeight
            )
        }
    }
}

private struct VisibleScreenHeightReader: NSViewRepresentable {
    let onChange: (CGFloat) -> Void

    func makeNSView(context: Context) -> VisibleScreenHeightProbeView {
        VisibleScreenHeightProbeView(onChange: onChange)
    }

    func updateNSView(_ nsView: VisibleScreenHeightProbeView, context: Context) {
        nsView.onChange = onChange
        nsView.reportVisibleHeight()
    }
}

private final class VisibleScreenHeightProbeView: NSView {
    var onChange: (CGFloat) -> Void

    init(onChange: @escaping (CGFloat) -> Void) {
        self.onChange = onChange
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        self.onChange = { _ in }
        super.init(coder: coder)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        reportVisibleHeight()
    }

    func reportVisibleHeight() {
        guard let screen = window?.screen ?? Self.screenContainingPointer() ?? NSScreen.main else {
            return
        }

        onChange(screen.visibleFrame.height)
    }

    private static func screenContainingPointer() -> NSScreen? {
        let pointerLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(pointerLocation)
        }
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
