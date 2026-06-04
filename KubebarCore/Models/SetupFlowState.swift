import Foundation

public enum WatchTargetLoadingState: Equatable, Sendable {
    case idle
    case loading
    case failed(String)
}

public enum SettingsTabSelection: Equatable, Hashable, Sendable {
    case appSettings
    case context(String)

    public var id: SettingsTabID {
        switch self {
        case .appSettings:
            return .appSettings
        case let .context(context):
            return .context(context)
        }
    }

    public var title: String {
        switch self {
        case .appSettings:
            return "App Settings"
        case let .context(context):
            return context
        }
    }

    public var helpText: String {
        switch self {
        case .appSettings:
            return "App Settings"
        case let .context(context):
            return context
        }
    }

    public var systemImageName: String {
        switch self {
        case .appSettings:
            return "gearshape"
        case .context:
            return "server.rack"
        }
    }
}

public struct SettingsTabID: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let appSettings = SettingsTabID(rawValue: "app-settings")

    public static func context(_ context: String) -> SettingsTabID {
        SettingsTabID(rawValue: "context:\(context)")
    }
}

public struct SetupFlowState: Equatable, Sendable {
    public static let settingsSaveFailureMessage = "Could not save settings. Try again."

    public var selectedContext: String?
    public var appSettingsSelectedContext: String?
    public var selectedSettingsTab: SettingsTabSelection
    public var availableContexts: [String]
    public var watchlist: WatchlistSelectionState
    public var watchlistsByContext: [String: WatchlistSelectionState]
    public var targetLoadingState: WatchTargetLoadingState
    public var configurationMessage: String?
    public var refreshCadence: RefreshCadence
    public var startAtLogin: StartAtLoginState
    public var healthShiftAlerts: HealthShiftAlertsState

    public init(
        selectedContext: String? = nil,
        appSettingsSelectedContext: String? = nil,
        selectedSettingsTab: SettingsTabSelection = .appSettings,
        availableContexts: [String] = [],
        watchlist: WatchlistSelectionState = WatchlistSelectionState(),
        watchlistsByContext: [String: WatchlistSelectionState] = [:],
        targetLoadingState: WatchTargetLoadingState = .idle,
        configurationMessage: String? = nil,
        refreshCadence: RefreshCadence = .default,
        startAtLogin: StartAtLoginState = StartAtLoginState(),
        healthShiftAlerts: HealthShiftAlertsState = HealthShiftAlertsState()
    ) {
        self.selectedContext = selectedContext
        self.appSettingsSelectedContext = appSettingsSelectedContext ?? selectedContext
        self.selectedSettingsTab = selectedSettingsTab
        self.availableContexts = availableContexts
        let defaultWatchlist = WatchlistSelectionState()
        let hasExplicitWatchlist = watchlist != defaultWatchlist
        var nextWatchlistsByContext = watchlistsByContext

        if let selectedContext, hasExplicitWatchlist {
            nextWatchlistsByContext[selectedContext] = watchlist
        }

        self.watchlist = if let selectedContext,
                            !hasExplicitWatchlist,
                            let savedWatchlist = nextWatchlistsByContext[selectedContext] {
            savedWatchlist
        } else {
            watchlist
        }
        self.watchlistsByContext = nextWatchlistsByContext
        self.targetLoadingState = targetLoadingState
        self.configurationMessage = configurationMessage
        self.refreshCadence = refreshCadence
        self.startAtLogin = startAtLogin
        self.healthShiftAlerts = healthShiftAlerts
    }

    public var isConfigured: Bool {
        guard let selectedContext = selectedContextForCompletedConfig else {
            return false
        }

        return !watchlistState(for: selectedContext).isNamespaceSelectionEmpty
    }

    public var contextTabs: [String] {
        Set(availableContexts).sorted()
    }

    public var settingsTabs: [SettingsTabSelection] {
        [.appSettings] + contextTabs.map { .context($0) }
    }

    public var selectedSettingsTabID: SettingsTabID {
        selectedSettingsTab.id
    }

    public func settingsTab(for id: SettingsTabID) -> SettingsTabSelection? {
        settingsTabs.first { $0.id == id }
    }

    public var selectedContextForCompletedConfig: String? {
        switch selectedSettingsTab {
        case .appSettings:
            return appSettingsSelectedContext ?? selectedContext
        case .context:
            return selectedContext
        }
    }

    public var needsSetup: Bool {
        !isConfigured
    }

    public var title: String {
        isConfigured ? "Kubebar is ready" : "Set up Kubebar"
    }

    public var subtitle: String {
        if let configurationMessage, !configurationMessage.isEmpty {
            return configurationMessage
        }

        if isConfigured {
            return "Kubebar will use your saved context and watchlist."
        }

        return "Choose the context Kubebar should remember, then pick the namespaces to watch."
    }

    public var contextHelpText: String {
        if let selectedContext {
            return "Saved context: \(selectedContext)"
        }

        if availableContexts.isEmpty {
            return "No contexts are available yet."
        }

        return "Choose the cluster context Kubebar should keep using."
    }

    public var watchlistHelpText: String {
        if !watchlist.isNamespaceSelectionEmpty {
            return watchlist.namespaceSelectionSummary
        }

        switch targetLoadingState {
        case .loading:
            return "Loading namespaces for the selected context."
        case let .failed(reason):
            return reason.isEmpty ? "Could not load namespaces." : reason
        case .idle:
            break
        }

        if watchlist.isNamespaceSelectionEmpty {
            return watchlist.emptyStateMessage
        }

        return watchlist.namespaceSelectionSummary
    }

    public var emptyWatchlistActionTitle: String {
        "Add namespace"
    }

    public func primaryActionTitle(isEditingExistingConfig: Bool) -> String {
        isEditingExistingConfig && isConfigured ? "Save Settings" : "Finish setup"
    }

    public mutating func selectContext(_ context: String?) {
        preserveCurrentWatchlist()
        selectedContext = context
        selectedSettingsTab = context.map { .context($0) } ?? .appSettings
        watchlist = context.flatMap { watchlistsByContext[$0] } ?? WatchlistSelectionState()
    }

    public mutating func selectAppSettingsTab() {
        preserveCurrentWatchlist()
        selectedSettingsTab = .appSettings
    }

    public func currentWatchlistsByContext() -> [String: WatchlistSelectionState] {
        var current = watchlistsByContext

        if let selectedContext {
            current[selectedContext] = watchlist
        }

        return current
    }

    public func watchlistState(for context: String) -> WatchlistSelectionState {
        if selectedContext == context {
            return watchlist
        }

        return watchlistsByContext[context] ?? WatchlistSelectionState()
    }

    private mutating func preserveCurrentWatchlist() {
        guard let selectedContext else {
            return
        }

        watchlistsByContext[selectedContext] = watchlist
    }
}
