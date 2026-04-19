import Foundation

public struct SetupFlowState: Equatable, Sendable {
    public var selectedContext: String?
    public var availableContexts: [String]
    public var watchlist: WatchlistSelectionState
    public var configurationMessage: String?

    public init(
        selectedContext: String? = nil,
        availableContexts: [String] = [],
        watchlist: WatchlistSelectionState = WatchlistSelectionState(),
        configurationMessage: String? = nil
    ) {
        self.selectedContext = selectedContext
        self.availableContexts = availableContexts
        self.watchlist = watchlist
        self.configurationMessage = configurationMessage
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
        if watchlist.isEmpty {
            return watchlist.emptyStateMessage
        }

        return watchlist.selectionSummary
    }

    public var emptyWatchlistActionTitle: String {
        "Add watch target"
    }

    public mutating func selectContext(_ context: String?) {
        selectedContext = context
    }
}
