import Foundation

public enum WatchTargetLoadingState: Equatable, Sendable {
    case idle
    case loading
    case failed(String)
}

public enum SettingsTabSelection: Equatable, Hashable, Sendable {
    case general
    case kubernetes
    case notifications
    case aiAssistant
    case context(String)

    public var id: SettingsTabID {
        switch self {
        case .general:
            return .general
        case .kubernetes:
            return .kubernetes
        case .notifications:
            return .notifications
        case .aiAssistant:
            return .aiAssistant
        case let .context(context):
            return .context(context)
        }
    }

    public var title: String {
        switch self {
        case .general:
            return "General"
        case .kubernetes:
            return "Kubernetes"
        case .notifications:
            return "Notifications"
        case .aiAssistant:
            return "AI Assistant"
        case let .context(context):
            return context
        }
    }

    public var helpText: String {
        switch self {
        case .general:
            return "General app settings"
        case .kubernetes:
            return "Kubeconfig discovery"
        case .notifications:
            return "Health shift alerts"
        case .aiAssistant:
            return "AI Diagnostic Assistant"
        case let .context(context):
            return context
        }
    }

    public var systemImageName: String {
        switch self {
        case .general:
            return "gearshape"
        case .kubernetes:
            return "square.3.layers.3d"
        case .notifications:
            return "bell"
        case .aiAssistant:
            return "sparkles"
        case .context:
            return "server.rack"
        }
    }

    public static var appSettings: SettingsTabSelection {
        .general
    }
}

public struct SettingsTabID: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let general = SettingsTabID(rawValue: "app-general")
    public static let kubernetes = SettingsTabID(rawValue: "app-kubernetes")
    public static let notifications = SettingsTabID(rawValue: "app-notifications")
    public static let aiAssistant = SettingsTabID(rawValue: "app-ai-assistant")

    public static let appSettings = SettingsTabID.general

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
    public var kubeconfigPaths: [String]
    public var aiDiagnosticAssistant: AIDiagnosticAssistantState

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
        healthShiftAlerts: HealthShiftAlertsState = HealthShiftAlertsState(),
        kubeconfigPaths: [String] = [],
        aiDiagnosticAssistant: AIDiagnosticAssistantState = AIDiagnosticAssistantState()
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
        self.kubeconfigPaths = kubeconfigPaths
        self.aiDiagnosticAssistant = aiDiagnosticAssistant
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

    public static var appPages: [SettingsTabSelection] {
        [.general, .kubernetes, .notifications, .aiAssistant]
    }

    public var settingsTabs: [SettingsTabSelection] {
        Self.appPages + contextTabs.map { .context($0) }
    }

    public var selectedSettingsTabID: SettingsTabID {
        selectedSettingsTab.id
    }

    public func settingsTab(for id: SettingsTabID) -> SettingsTabSelection? {
        settingsTabs.first { $0.id == id }
    }

    public var selectedContextForCompletedConfig: String? {
        switch selectedSettingsTab {
        case .general, .kubernetes, .notifications, .aiAssistant:
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

    public var usesAutomaticKubeconfigDetection: Bool {
        kubeconfigPaths.isEmpty
    }

    public func primaryActionTitle(isEditingExistingConfig: Bool) -> String {
        isEditingExistingConfig && isConfigured ? "Save Settings" : "Finish setup"
    }

    public mutating func selectContext(_ context: String?) {
        preserveCurrentWatchlist()
        selectedContext = context
        selectedSettingsTab = context.map { .context($0) } ?? .general
        watchlist = context.flatMap { watchlistsByContext[$0] } ?? WatchlistSelectionState()
    }

    public mutating func selectAppSettingsTab() {
        selectAppPage(.general)
    }

    public mutating func selectAppPage(_ page: SettingsTabSelection) {
        guard Self.appPages.contains(page) else {
            return
        }
        preserveCurrentWatchlist()
        selectedSettingsTab = page
        configurationMessage = nil
    }

    public mutating func appendKubeconfigPaths(_ paths: [String]) {
        var seen = Set(kubeconfigPaths)
        var appended: [String] = []

        for rawPath in paths {
            let path = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !path.isEmpty, !seen.contains(path) else {
                continue
            }

            seen.insert(path)
            appended.append(path)
        }

        guard !appended.isEmpty else {
            return
        }

        kubeconfigPaths.append(contentsOf: appended)
        configurationMessage = nil
    }

    public mutating func removeKubeconfigPath(at index: Int) {
        guard kubeconfigPaths.indices.contains(index) else {
            return
        }

        kubeconfigPaths.remove(at: index)
        configurationMessage = nil
    }

    public mutating func moveKubeconfigPathUp(at index: Int) {
        guard kubeconfigPaths.indices.contains(index), index > 0 else {
            return
        }

        kubeconfigPaths.swapAt(index, index - 1)
        configurationMessage = nil
    }

    public mutating func moveKubeconfigPathDown(at index: Int) {
        guard kubeconfigPaths.indices.contains(index), index < kubeconfigPaths.index(before: kubeconfigPaths.endIndex) else {
            return
        }

        kubeconfigPaths.swapAt(index, index + 1)
        configurationMessage = nil
    }

    public mutating func replaceAvailableContexts(_ contexts: [String]) {
        availableContexts = Array(Set(contexts)).sorted()

        guard case let .context(context) = selectedSettingsTab, !availableContexts.contains(context) else {
            return
        }

        selectAppSettingsTab()
        targetLoadingState = .idle
        watchlist.clearAvailableTargets()
    }

    public mutating func updateAIDiagnosticAssistant(modelID: String) {
        aiDiagnosticAssistant.config.modelID = modelID
        configurationMessage = nil
    }

    public mutating func updateAIDiagnosticAssistant(baseURL: String?) {
        aiDiagnosticAssistant.config = aiDiagnosticAssistant.config.with(baseURL: baseURL)
        configurationMessage = nil
    }

    public mutating func updateAIDiagnosticAssistant(provider: AIProvider) {
        aiDiagnosticAssistant.config = AIDiagnosticAssistantConfig(
            provider: provider,
            modelID: aiDiagnosticAssistant.config.modelID,
            baseURL: aiDiagnosticAssistant.config.baseURL
        )
        aiDiagnosticAssistant.testConnectionResult = nil
        configurationMessage = nil
    }

    public mutating func updateAIDiagnosticAssistantAPIKeyDraft(_ draft: String) {
        aiDiagnosticAssistant.apiKeyDraft = draft
        configurationMessage = nil
    }

    public mutating func applyAIDiagnosticAssistantTestConnectionResult(_ result: AIProviderConnectionResult?) {
        aiDiagnosticAssistant.testConnectionResult = result
        configurationMessage = nil
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
