import AppKit
import SwiftUI
import KubebarCore

@main
struct KubebarApp: App {
    @StateObject private var viewModel = MenuBarViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(
                display: viewModel.display,
                isShowingSetup: viewModel.isShowingSetup,
                refreshCadence: viewModel.refreshCadence,
                isRefreshing: viewModel.isRefreshing,
                onRefresh: viewModel.refreshNow,
                onPrepareSettings: viewModel.prepareSettings,
                onQuit: { NSApplication.shared.terminate(nil) },
                onSelectRefreshCadence: viewModel.selectRefreshCadence
            )
        } label: {
            let presentation = MenuBarStatusPresentation(state: viewModel.display.state)
            switch presentation.icon {
            case let .system(name):
                Label(presentation.accessibilityLabel, systemImage: name)
            case let .custom(name):
                Image(name)
                    .accessibilityLabel(presentation.accessibilityLabel)
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsRootView(
                state: $viewModel.setupState,
                isEditingExistingConfig: viewModel.isEditingExistingConfiguration,
                onPrepare: viewModel.prepareSettings,
                onComplete: viewModel.completeSetup,
                onSelectContext: viewModel.selectSetupContext,
                onRetryTargets: viewModel.retryWatchTargetLoad
            )
        }
    }
}
