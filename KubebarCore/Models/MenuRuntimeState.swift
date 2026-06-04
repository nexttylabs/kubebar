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
        self.setupState = Self.setupState(from: config)
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

    public var contextSelectorContexts: [String] {
        setupState.contextTabs
    }

    public mutating func applyActiveConfig(_ config: AppConfig) {
        let availableContexts = setupState.availableContexts

        surface = config.needsSetup ? .setup : .menu
        setupState = Self.setupState(from: config)
        setupState.availableContexts = availableContexts
    }

    public mutating func openSetup() {
        surface = .setup
        setupState.configurationMessage = nil
    }

    public mutating func prepareSettings(config: AppConfig) {
        guard !hasUnsavedSettingsChanges(comparedTo: config) else {
            return
        }

        setupState = Self.setupState(from: config)
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

    public mutating func selectAppSettingsTab() {
        setupState.selectAppSettingsTab()
        setupState.configurationMessage = nil
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

    public mutating func applyStartAtLoginState(_ startAtLogin: StartAtLoginState) {
        setupState.startAtLogin = startAtLogin
    }

    public mutating func applyHealthShiftAlertsState(_ healthShiftAlerts: HealthShiftAlertsState) {
        setupState.healthShiftAlerts = healthShiftAlerts
        setupState.configurationMessage = nil
    }

    public mutating func completeSetupSaved() {
        surface = .menu
        setupState.configurationMessage = nil
    }

    public func completedConfig() -> AppConfig? {
        let watchlistsByContext = completedWatchlistsByContext()
        guard let selectedContext = setupState.selectedContextForCompletedConfig,
              !(watchlistsByContext[selectedContext] ?? []).isEmpty else {
            return nil
        }

        return AppConfig(
            selectedContext: selectedContext,
            watchlistsByContext: watchlistsByContext,
            refreshIntervalSeconds: setupState.refreshCadence.seconds,
            healthShiftAlertsEnabled: setupState.healthShiftAlerts.isEnabled
        )
    }

    private func hasUnsavedSettingsChanges(comparedTo config: AppConfig) -> Bool {
        setupState.selectedContextForCompletedConfig != config.selectedContext ||
            completedWatchlistsByContext() != Self.namespaceWatchlists(from: config.watchlistsByContext) ||
            setupState.refreshCadence.seconds != config.refreshIntervalSeconds ||
            setupState.healthShiftAlerts.isEnabled != config.healthShiftAlertsEnabled
    }

    private func completedWatchlistsByContext() -> [String: [WatchTarget]] {
        Self.namespaceWatchlists(
            from: setupState.currentWatchlistsByContext().mapValues { Array($0.selectedNamespaceTargets) }
        )
    }

    private static func watchlistStates(from watchlistsByContext: [String: [WatchTarget]]) -> [String: WatchlistSelectionState] {
        watchlistsByContext.mapValues { targets in
            WatchlistSelectionState(selectedTargets: namespaceTargets(from: targets))
        }
    }

    private static func setupState(from config: AppConfig) -> SetupFlowState {
        SetupFlowState(
            selectedContext: config.selectedContext,
            watchlistsByContext: watchlistStates(from: config.watchlistsByContext),
            refreshCadence: config.refreshCadence,
            healthShiftAlerts: HealthShiftAlertsState(isEnabled: config.healthShiftAlertsEnabled)
        )
    }

    private static func namespaceWatchlists(from watchlistsByContext: [String: [WatchTarget]]) -> [String: [WatchTarget]] {
        watchlistsByContext.reduce(into: [:]) { result, item in
            let targets = namespaceTargets(from: item.value).sorted { $0.displayTitle < $1.displayTitle }

            if !targets.isEmpty {
                result[item.key] = targets
            }
        }
    }

    private static func namespaceTargets(from targets: [WatchTarget]) -> Set<WatchTarget> {
        Set(targets.filter { target in
            if case .namespace = target {
                return true
            }

            return false
        })
    }
}
