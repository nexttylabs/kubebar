import AppKit
import SwiftUI

@MainActor
final class PodLogWindowPresenter: NSObject {
    private var window: NSWindow?
    private var activeTargetID: String?
    private var isClosingFromViewModel = false
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }

    func present(viewModel: MenuBarViewModel) {
        guard let drawer = viewModel.podLogDrawer else {
            closeFromViewModel()
            return
        }

        let targetChanged = activeTargetID != drawer.target.id
        activeTargetID = drawer.target.id

        guard window == nil || targetChanged else {
            window?.title = "Logs: \(drawer.target.podName)"
            return
        }

        let content = PodLogWindowContent(viewModel: viewModel)

        let hostingController = NSHostingController(rootView: content)
        let logWindow = window ?? makeWindow()
        logWindow.contentViewController = hostingController
        logWindow.title = "Logs: \(drawer.target.podName)"

        if window == nil {
            window = logWindow
        }

        bringToFront(logWindow)
    }

    func closeFromViewModel() {
        guard let window else {
            return
        }

        isClosingFromViewModel = true
        window.close()
        isClosingFromViewModel = false
        self.window = nil
        activeTargetID = nil
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 520, height: 360)
        window.center()
        return window
    }

    private func bringToFront(_ window: NSWindow) {
        let application = NSApplication.shared
        application.activate(ignoringOtherApps: true)

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
    }
}

extension PodLogWindowPresenter: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        window = nil
        activeTargetID = nil

        guard !isClosingFromViewModel else {
            return
        }

        onClose()
    }
}

private struct PodLogWindowContent: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        if let drawer = viewModel.podLogDrawer {
            PodLogDrawerView(
                drawer: drawer,
                searchQuery: $viewModel.podLogSearchQuery,
                onCopyLogs: viewModel.copyCurrentPodLogs
            )
        }
    }
}
