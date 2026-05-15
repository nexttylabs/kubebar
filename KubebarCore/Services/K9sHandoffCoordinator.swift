import Foundation

public enum K9sHandoffLaunchState: Equatable, Sendable {
    case idle
    case opening(target: OverviewK9sHandoff)
    case failed(target: OverviewK9sHandoff, message: String)

    public var target: OverviewK9sHandoff? {
        switch self {
        case .idle:
            nil
        case let .opening(target: target):
            target
        case let .failed(target: target, message: _):
            target
        }
    }

    public var message: String? {
        switch self {
        case .idle:
            nil
        case .opening:
            "Opening k9s..."
        case let .failed(_, message):
            message
        }
    }

    public var isOpening: Bool {
        if case .opening = self {
            true
        } else {
            false
        }
    }
}

public extension K9sHandoffLaunchState {
    func isOpeningForSameTarget(_ handoff: OverviewK9sHandoff) -> Bool {
        switch self {
        case let .opening(target):
            target == handoff
        default:
            false
        }
    }

    func blocksNewHandoff(for _: OverviewK9sHandoff) -> Bool {
        isOpening
    }

    func feedbackMessage(for handoff: OverviewK9sHandoff) -> String? {
        switch self {
        case .idle:
            nil
        case .opening(let target):
            target == handoff ? "Opening k9s..." : nil
        case .failed(let target, let message):
            target == handoff ? message : nil
        }
    }
}

@MainActor
public final class K9sHandoffCoordinator {
    public private(set) var state: K9sHandoffLaunchState = .idle
    public var onStateChange: ((K9sHandoffLaunchState) -> Void)?

    private let launcher: K9sHandoffLaunching
    private var launchTask: Task<Void, Never>?

    public init(launcher: K9sHandoffLaunching = K9sHandoffLauncher()) {
        self.launcher = launcher
    }

    public func open(for handoff: OverviewK9sHandoff?) {
        guard let handoff else {
            clear()
            return
        }

        if case .opening = state {
            return
        }

        transition(to: .opening(target: handoff))

        let launchTarget = handoff.target
        launchTask = Task(priority: .userInitiated) { [weak self, launcher = launcher] in
            do {
                try await Task.detached(priority: .userInitiated) {
                    try launcher.launch(target: launchTarget)
                }.value

                self?.completeLaunch()
            } catch {
                self?.failLaunch(for: handoff)
            }
        }
    }

    public func clear() {
        launchTask?.cancel()
        launchTask = nil
        transition(to: .idle)
    }

    public func resetIfTargetUnavailable(_ handoff: OverviewK9sHandoff?) {
        guard let handoff else {
            clear()
            return
        }

        guard state.target == handoff else {
            clear()
            return
        }
    }

    private func completeLaunch() {
        launchTask = nil
        transition(to: .idle)
    }

    private func failLaunch(for handoff: OverviewK9sHandoff) {
        launchTask = nil
        transition(
            to: .failed(
                target: handoff,
                message: "Could not open k9s for \(handoff.target.contextName)/\(handoff.target.displayName)"
            )
        )
    }

    private func transition(to next: K9sHandoffLaunchState) {
        if state == next {
            return
        }

        state = next
        onStateChange?(state)
    }
}
