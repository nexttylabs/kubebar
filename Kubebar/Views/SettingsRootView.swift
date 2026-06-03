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
            onToggleHealthShiftAlerts: onToggleHealthShiftAlerts
        )
        .frame(
            width: SettingsWindowLayout.width,
            height: SettingsWindowLayout.height,
            alignment: .topLeading
        )
        .background(SettingsWindowFocusBridge())
        .onAppear(perform: onPrepare)
    }

    private func completeAndDismissIfSaved() {
        guard onComplete() else {
            return
        }

        dismiss()
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
    func makeNSView(context: Context) -> SettingsWindowProbeView {
        SettingsWindowProbeView()
    }

    func updateNSView(_ nsView: SettingsWindowProbeView, context: Context) {
        nsView.registerWindowIfAvailable()
    }
}

private final class SettingsWindowProbeView: NSView {
    private var didBringWindowToFront = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        registerWindowIfAvailable()
    }

    func registerWindowIfAvailable() {
        guard let window else {
            return
        }

        SettingsWindowPresenter.register(window)

        guard !didBringWindowToFront else {
            return
        }

        didBringWindowToFront = true
        SettingsWindowPresenter.bringToFront()
    }
}
