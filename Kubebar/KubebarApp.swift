import AppKit
import SwiftUI
import KubebarCore

@main
struct KubebarApp: App {
    @StateObject private var viewModel = MenuBarViewModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(
                display: viewModel.display,
                setupState: $viewModel.setupState,
                isShowingSetup: viewModel.isShowingSetup,
                onRefresh: viewModel.refreshNow,
                onEditWatchlist: viewModel.openSetup,
                onCompleteSetup: viewModel.completeSetup
            )
        } label: {
            let presentation = MenuBarStatusPresentation(state: viewModel.display.state)
            Label(presentation.accessibilityLabel, systemImage: presentation.symbolName)
        }
        .menuBarExtraStyle(.window)
    }
}
