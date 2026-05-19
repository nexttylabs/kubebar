import Foundation

public enum WatchTargetLoadingState: Equatable, Sendable {
    case idle
    case loading
    case failed(String)
}

public struct SetupFlowState: Equatable, Sendable {
    public static let settingsSaveFailureMessage = "Could not save settings. Try again."

    public var selectedContext: String?
    public var availableContexts: [String]
    public var watchlist: WatchlistSelectionState
    public var targetLoadingState: WatchTargetLoadingState
    public var configurationMessage: String?
    public var refreshCadence: RefreshCadence
    public var startAtLogin: StartAtLoginState

    public init(
        selectedContext: String? = nil,
        availableContexts: [String] = [],
        watchlist: WatchlistSelectionState = WatchlistSelectionState(),
        targetLoadingState: WatchTargetLoadingState = .idle,
        configurationMessage: String? = nil,
        refreshCadence: RefreshCadence = .default,
        startAtLogin: StartAtLoginState = StartAtLoginState()
    ) {
        self.selectedContext = selectedContext
        self.availableContexts = availableContexts
        self.watchlist = watchlist
        self.targetLoadingState = targetLoadingState
        self.configurationMessage = configurationMessage
        self.refreshCadence = refreshCadence
        self.startAtLogin = startAtLogin
    }

    public var isConfigured: Bool {
        selectedContext != nil && !watchlist.isNamespaceSelectionEmpty
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
        selectedContext = context
    }
}
