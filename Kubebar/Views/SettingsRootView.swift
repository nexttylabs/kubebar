import AppKit
import SwiftUI
import KubebarCore

struct SettingsRootView: View {
    @Binding var state: SetupFlowState
    let isEditingExistingConfig: Bool
    let onPrepare: () -> Void
    let onComplete: () -> Bool
    let onSelectAppSettings: () -> Void
    let onSelectContext: (String?) -> Void
    let onRetryTargets: () -> Void
    let onToggleStartAtLogin: (Bool) -> Void
    let onToggleHealthShiftAlerts: (Bool) -> Void
    let onAddKubeconfigPaths: ([String]) -> Void
    let onRemoveKubeconfigPath: (Int) -> Void
    let onMoveKubeconfigPathUp: (Int) -> Void
    let onMoveKubeconfigPathDown: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SetupView(
            state: $state,
            primaryActionTitle: state.primaryActionTitle(isEditingExistingConfig: isEditingExistingConfig),
            onComplete: completeAndDismissIfSaved,
            onSelectAppSettings: onSelectAppSettings,
            onSelectContext: onSelectContext,
            onRetryTargets: onRetryTargets,
            onToggleStartAtLogin: onToggleStartAtLogin,
            onToggleHealthShiftAlerts: onToggleHealthShiftAlerts,
            onAddKubeconfigPaths: chooseKubeconfigPaths,
            onRemoveKubeconfigPath: onRemoveKubeconfigPath,
            onMoveKubeconfigPathUp: onMoveKubeconfigPathUp,
            onMoveKubeconfigPathDown: onMoveKubeconfigPathDown
        )
        .frame(
            width: SettingsWindowLayout.width,
            height: SettingsWindowLayout.height,
            alignment: .topLeading
        )
        .background(SettingsWindowFocusBridge(title: "Kubebar Settings"))
        .onAppear(perform: onPrepare)
    }

    private func completeAndDismissIfSaved() {
        guard onComplete() else {
            return
        }

        dismiss()
    }

    private func chooseKubeconfigPaths() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.resolvesAliases = true
        panel.title = "Choose kubeconfig files"
        panel.message = "Add one or more kubeconfig files to use for kubectl reads."

        guard panel.runModal() == .OK else {
            return
        }

        onAddKubeconfigPaths(panel.urls.map(\.path))
    }
}

private enum SettingsWindowLayout {
    static let width: CGFloat = 640
    static let height: CGFloat = 560
}

@MainActor
enum SettingsWindowPresenter {
    private static weak var settingsWindow: NSWindow?

    static func register(_ window: NSWindow) {
        settingsWindow = window
    }

    static func bringToFrontAfterOpening() {
        bringToFront()

        Task { @MainActor in
            bringToFront()
        }
    }

    static func bringToFront() {
        let application = NSApplication.shared
        application.activate(ignoringOtherApps: true)

        guard let settingsWindow else {
            return
        }

        if settingsWindow.isMiniaturized {
            settingsWindow.deminiaturize(nil)
        }

        settingsWindow.orderFrontRegardless()
        settingsWindow.makeKeyAndOrderFront(nil)
    }
}

private struct SettingsWindowFocusBridge: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> SettingsWindowProbeView {
        SettingsWindowProbeView(title: title)
    }

    func updateNSView(_ nsView: SettingsWindowProbeView, context: Context) {
        nsView.title = title
        nsView.registerWindowIfAvailable()
    }
}

private final class SettingsWindowProbeView: NSView {
    private var didBringWindowToFront = false
    var title: String {
        didSet {
            applyWindowTitle()
        }
    }

    init(title: String) {
        self.title = title
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        self.title = "Kubebar Settings"
        super.init(coder: coder)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        registerWindowIfAvailable()
    }

    func registerWindowIfAvailable() {
        guard let window else {
            return
        }

        SettingsWindowPresenter.register(window)
        applyWindowTitle()

        Task { @MainActor [weak self] in
            self?.applyWindowTitle()
        }

        guard !didBringWindowToFront else {
            return
        }

        didBringWindowToFront = true
        SettingsWindowPresenter.bringToFront()
    }

    private func applyWindowTitle() {
        window?.title = title
    }
}
