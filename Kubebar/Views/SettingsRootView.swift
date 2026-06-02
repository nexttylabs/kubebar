import AppKit
import SwiftUI
import KubebarCore

struct SettingsRootView: View {
    @Binding var state: SetupFlowState
    let isEditingExistingConfig: Bool
    let onPrepare: () -> Void
    let onComplete: () -> Bool
    let onSelectContext: (String?) -> Void
    let onRetryTargets: () -> Void
    let onToggleStartAtLogin: (Bool) -> Void
    let onToggleHealthShiftAlerts: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight = SettingsWindowLayout.minimumHeight

    var body: some View {
        SetupView(
            state: $state,
            primaryActionTitle: state.primaryActionTitle(isEditingExistingConfig: isEditingExistingConfig),
            onComplete: completeAndDismissIfSaved,
            onSelectContext: onSelectContext,
            onRetryTargets: onRetryTargets,
            onToggleStartAtLogin: onToggleStartAtLogin,
            onToggleHealthShiftAlerts: onToggleHealthShiftAlerts,
            onContentHeightChange: updateContentHeight
        )
        .frame(
            width: SettingsWindowLayout.width,
            height: settingsWindowHeight,
            alignment: .topLeading
        )
        .background(SettingsWindowFocusBridge())
        .onAppear(perform: onPrepare)
    }

    private var settingsWindowHeight: CGFloat {
        min(
            max(contentHeight, SettingsWindowLayout.minimumHeight),
            SettingsWindowLayout.maximumHeight
        )
    }

    private func completeAndDismissIfSaved() {
        guard onComplete() else {
            return
        }

        dismiss()
    }

    private func updateContentHeight(_ height: CGFloat) {
        guard height > 0, abs(contentHeight - height) > SettingsWindowLayout.heightTolerance else {
            return
        }

        contentHeight = height
    }
}

private enum SettingsWindowLayout {
    static let width: CGFloat = 560
    static let minimumHeight: CGFloat = 380
    static let maximumHeight: CGFloat = 680
    static let heightTolerance: CGFloat = 1
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
