import AppKit
import SwiftUI
import KubebarCore

@main
struct KubebarApp: App {
    @StateObject private var viewModel = MenuBarViewModel()
#if DEBUG
    private let qaFixture = QALaunchMode.fixture()
#endif

    var body: some Scene {
        menuScene

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

    @SceneBuilder
    private var menuScene: some Scene {
        MenuBarExtra {
            menuRootView
        } label: {
            let presentation = MenuBarStatusPresentation(state: menuState)
            switch presentation.icon {
            case let .system(name):
                Label(presentation.accessibilityLabel, systemImage: name)
            case let .custom(name):
                Image(name)
                    .accessibilityLabel(presentation.accessibilityLabel)
            }
        }
        .menuBarExtraStyle(.window)
    }

    private var menuState: ClusterHealthState {
#if DEBUG
        if let qaFixture {
            return qaFixture.display.state
        }
#endif
        return viewModel.display.state
    }

    @ViewBuilder
    private var menuRootView: some View {
#if DEBUG
        if let qaFixture {
            QAFixtureMenuRootView(fixture: qaFixture)
        } else {
            liveMenuRootView
        }
#else
        liveMenuRootView
#endif
    }

    private var liveMenuRootView: some View {
        MenuBarRootView(
            display: viewModel.display,
            isShowingSetup: viewModel.isShowingSetup,
            isRefreshing: viewModel.isRefreshing,
            onRefresh: viewModel.refreshNow,
            onPrepareSettings: viewModel.prepareSettings,
            k9sHandoffState: viewModel.k9sHandoffState,
            onOpenK9sHandoff: viewModel.openK9sHandoff,
            onQuit: { NSApplication.shared.terminate(nil) }
        )
    }
}

#if DEBUG
private struct QAFixtureMenuRootView: View {
    let fixture: MenuStateFixture

    init(fixture: MenuStateFixture) {
        self.fixture = fixture
    }

    var body: some View {
        MenuBarRootView(
            display: fixture.display,
            isShowingSetup: fixture.isShowingSetup,
            isRefreshing: false,
            onRefresh: {},
            onPrepareSettings: {},
            k9sHandoffState: .idle,
            onOpenK9sHandoff: {},
            onQuit: { NSApplication.shared.terminate(nil) }
        )
    }
}
#endif
