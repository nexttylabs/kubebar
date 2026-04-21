import Foundation

public enum MenuSurface: Equatable, Sendable {
    case setup
    case menu
}

public struct MenuRuntimeState: Equatable, Sendable {
    public private(set) var surface: MenuSurface
    public var setupState: SetupFlowState

    public init(config: AppConfig) {
        self.surface = config.needsSetup ? .setup : .menu
        self.setupState = SetupFlowState(
            selectedContext: config.selectedContext,
            watchlist: WatchlistSelectionState(selectedTargets: Set(config.watchTargets)),
            refreshCadence: config.refreshCadence
        )
    }

    public var isShowingSetup: Bool {
        surface == .setup
    }

    public var shouldLoadContexts: Bool {
        isShowingSetup
    }

    public var targetContextToLoad: String? {
        guard isShowingSetup else {
            return nil
        }

        return setupState.selectedContext
    }

    public mutating func openSetup() {
        surface = .setup
        setupState.configurationMessage = nil
    }

    @discardableResult
    public mutating func selectContext(_ context: String?) -> String? {
        setupState.selectContext(context)
        setupState.watchlist.clearAvailableTargets()
        setupState.configurationMessage = nil

        guard let context else {
            setupState.targetLoadingState = .idle
            return nil
        }

        setupState.targetLoadingState = .loading
        return context
    }

    public mutating func beginTargetLoading(for context: String) {
        guard setupState.selectedContext == context else {
            return
        }

        setupState.targetLoadingState = .loading
    }

    public mutating func applyTargetLoadSuccess(_ candidates: WatchlistCandidates, for context: String) {
        guard setupState.selectedContext == context else {
            return
        }

        setupState.watchlist.replaceAvailableTargets(candidates)
        setupState.targetLoadingState = .idle
    }

    public mutating func applyTargetLoadFailure(_ reason: String, for context: String) {
        guard setupState.selectedContext == context else {
            return
        }

        setupState.targetLoadingState = .failed(reason)
    }

    public mutating func markConfigurationSaveFailed(_ message: String) {
        setupState.configurationMessage = message
    }

    public mutating func selectRefreshCadence(_ cadence: RefreshCadence) {
        setupState.refreshCadence = cadence
        setupState.configurationMessage = nil
    }

    public mutating func completeSetupSaved() {
        surface = .menu
        setupState.configurationMessage = nil
    }

    public func completedConfig() -> AppConfig? {
        guard let selectedContext = setupState.selectedContext, !setupState.watchlist.selectedTargets.isEmpty else {
            return nil
        }

        return AppConfig(
            selectedContext: selectedContext,
            watchTargets: setupState.watchlist.selectedTargets.sorted { $0.displayTitle < $1.displayTitle },
            refreshIntervalSeconds: setupState.refreshCadence.seconds
        )
    }
}
