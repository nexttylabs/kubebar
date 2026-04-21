import Foundation

public enum WatchTargetLoadingState: Equatable, Sendable {
    case idle
    case loading
    case failed(String)
}

public struct SetupFlowState: Equatable, Sendable {
    public var selectedContext: String?
    public var availableContexts: [String]
    public var watchlist: WatchlistSelectionState
    public var targetLoadingState: WatchTargetLoadingState
    public var configurationMessage: String?
    public var refreshCadence: RefreshCadence

    public init(
        selectedContext: String? = nil,
        availableContexts: [String] = [],
        watchlist: WatchlistSelectionState = WatchlistSelectionState(),
        targetLoadingState: WatchTargetLoadingState = .idle,
        configurationMessage: String? = nil,
        refreshCadence: RefreshCadence = .default
    ) {
        self.selectedContext = selectedContext
        self.availableContexts = availableContexts
        self.watchlist = watchlist
        self.targetLoadingState = targetLoadingState
        self.configurationMessage = configurationMessage
        self.refreshCadence = refreshCadence
    }

    public var isConfigured: Bool {
        selectedContext != nil && !watchlist.isEmpty
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

        return "Choose the context Kubebar should remember, then pick the namespaces and workloads to watch."
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
        if !watchlist.isEmpty {
            return watchlist.selectionSummary
        }

        switch targetLoadingState {
        case .loading:
            return "Loading watch targets for the selected context."
        case let .failed(reason):
            return reason.isEmpty ? "Could not load watch targets." : reason
        case .idle:
            break
        }

        if watchlist.isEmpty {
            return watchlist.emptyStateMessage
        }

        return watchlist.selectionSummary
    }

    public var emptyWatchlistActionTitle: String {
        "Add watch target"
    }

    public var refreshCadenceHelpText: String {
        "Refresh every \(refreshCadence.label)."
    }

    public mutating func selectContext(_ context: String?) {
        selectedContext = context
    }
}
