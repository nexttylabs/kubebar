import AppKit
import Foundation
import SwiftUI
import KubebarCore

struct PodLogDrawerPresentation: Identifiable, Equatable {
    fileprivate let session: PodLogStreamSession
    var target: PodLogTarget
    var state: PodLogDrawerState
    var buffer: PodLogBuffer
    var aiDiagnosis: AIPodDiagnosisState

    var id: String {
        target.id
    }

    var visibleText: String {
        buffer.text
    }

    func matchCount(for query: String) -> Int {
        buffer.matchCount(for: query)
    }
}

struct EventDiagnosisPresentation: Identifiable, Equatable {
    var target: WarningEventDiagnosticTarget
    var state: AIEventDiagnosisState

    var id: String {
        target.id
    }
}

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published private(set) var display: MenuDisplayModel
    @Published private(set) var activeContextName: String?
    @Published var setupState: SetupFlowState {
        didSet {
            guard !isPublishingRuntimeState else {
                return
            }

            runtimeState.setupState = setupState
        }
    }
    @Published private(set) var isShowingSetup: Bool
    @Published private(set) var isRefreshing: Bool
    @Published private(set) var k9sHandoffState: K9sHandoffLaunchState
    @Published private(set) var podLogDrawer: PodLogDrawerPresentation?
    @Published private(set) var eventDiagnosis: EventDiagnosisPresentation?
    @Published var podLogSearchQuery: String = ""

    private let configStore: AppConfigStore
    private let refreshCoordinator: RefreshCoordinator
    private let contextCatalog: ContextCatalog
    private let watchTargetCatalog: any WatchTargetCataloging
    private var config: AppConfig
    private var snapshot: ClusterSnapshot?
    private var runtimeState: MenuRuntimeState
    private var isPublishingRuntimeState: Bool
    private var refreshLoopTask: Task<Void, Never>?
    private var freshnessTimerTask: Task<Void, Never>?
    private var watchTargetLoadTask: Task<Void, Never>?
    private var networkRecoveryTask: Task<Void, Never>?
    private var refreshGate: RefreshGate
    private var staleReason: String?
    private let k9sHandoffCoordinator: K9sHandoffCoordinator
    private let startAtLoginSettings: StartAtLoginSettingsCoordinator
    private let healthShiftAlertSettings: HealthShiftAlertSettingsCoordinator
    private let healthShiftAlertNotifier: any HealthShiftAlertNotifying
    private let networkReachability: any NetworkReachability
    private let podLogStreamer: any PodLogStreaming
    private let podDiagnosticLogReader: any PodDiagnosticLogReading
    private let warningEventDiagnosticReader: any WarningEventDiagnosticReading
    private let aiCredentialStore: any AIProviderCredentialStoring
    private let aiConnectionTester: AIProviderConnectionTester?
    private let aiPodDiagnosticRequester: AIPodDiagnosticRequester?
    private let aiEventDiagnosticRequester: AIEventDiagnosticRequester?
    private var isNetworkAvailable: Bool = true
    private var healthShiftAlertTracker: HealthShiftAlertTracker
    private var healthShiftAlertSettingsRequestGate: HealthShiftAlertSettingsRequestGate
    private var podLogStreamTask: Task<Void, Never>?
    private var podDiagnosisTask: Task<Void, Never>?
    private var eventDiagnosisTask: Task<Void, Never>?
    private var activePodLogSession: PodLogStreamSession?

    /// Delay before resuming automatic refresh after network recovery.
    /// Avoids rapid kubectl calls during unstable Wi-Fi reconnection.
    private static let networkRecoveryDebounceNanoseconds: UInt64 = 2_000_000_000
    private static let aiCredentialSaveFailureMessage = "Could not save API key. Check macOS Keychain access."

    init(
        configStore: AppConfigStore = AppConfigStore(directory: MenuBarViewModel.defaultConfigDirectory),
        refreshCoordinator: RefreshCoordinator = RefreshCoordinator(),
        contextCatalog: ContextCatalog = ContextCatalog(),
        watchTargetCatalog: any WatchTargetCataloging = WatchTargetCatalog(),
        k9sHandoffCoordinator: K9sHandoffCoordinator = K9sHandoffCoordinator(),
        startAtLoginSettings: StartAtLoginSettingsCoordinator = StartAtLoginSettingsCoordinator(
            controller: SystemStartAtLoginController()
        ),
        healthShiftAlertNotifier: any HealthShiftAlertNotifying = SystemHealthShiftAlertNotifier(),
        networkReachability: any NetworkReachability = NetworkReachabilityMonitor(),
        podLogStreamer: any PodLogStreaming = ProcessPodLogStreamer(),
        podDiagnosticLogReader: any PodDiagnosticLogReading = CommandPodDiagnosticLogReader(),
        warningEventDiagnosticReader: any WarningEventDiagnosticReading = CommandWarningEventDiagnosticReader(),
        aiCredentialStore: any AIProviderCredentialStoring = KeychainAIProviderCredentialStore(),
        aiConnectionTester: AIProviderConnectionTester? = AIProviderConnectionTester(
            credentialStore: KeychainAIProviderCredentialStore(),
            httpClient: URLSessionHTTPClient()
        ),
        aiPodDiagnosticRequester: AIPodDiagnosticRequester? = AIPodDiagnosticRequester(
            credentialStore: KeychainAIProviderCredentialStore(),
            httpClient: URLSessionHTTPClient()
        ),
        aiEventDiagnosticRequester: AIEventDiagnosticRequester? = AIEventDiagnosticRequester(
            credentialStore: KeychainAIProviderCredentialStore(),
            httpClient: URLSessionHTTPClient()
        ),
        now: Date = Date()
    ) {
        self.configStore = configStore
        self.refreshCoordinator = refreshCoordinator
        self.contextCatalog = contextCatalog
        self.watchTargetCatalog = watchTargetCatalog
        self.k9sHandoffCoordinator = k9sHandoffCoordinator
        self.startAtLoginSettings = startAtLoginSettings
        self.healthShiftAlertSettings = HealthShiftAlertSettingsCoordinator(authorizer: healthShiftAlertNotifier)
        self.healthShiftAlertNotifier = healthShiftAlertNotifier
        self.networkReachability = networkReachability
        self.podLogStreamer = podLogStreamer
        self.podDiagnosticLogReader = podDiagnosticLogReader
        self.warningEventDiagnosticReader = warningEventDiagnosticReader
        self.aiCredentialStore = aiCredentialStore
        self.aiConnectionTester = aiConnectionTester
        self.aiPodDiagnosticRequester = aiPodDiagnosticRequester
        self.aiEventDiagnosticRequester = aiEventDiagnosticRequester

        do {
            self.config = try configStore.load()
        } catch {
            self.config = AppConfig()
        }

        self.snapshot = nil
        let runtimeState = MenuRuntimeState(config: config)
        self.runtimeState = runtimeState
        self.isPublishingRuntimeState = false
        self.setupState = runtimeState.setupState
        self.isShowingSetup = runtimeState.isShowingSetup
        self.isRefreshing = false
        self.refreshGate = RefreshGate()
        self.staleReason = nil
        self.display = Self.initialDisplay(for: config, now: now)
        self.activeContextName = config.selectedContext
        self.k9sHandoffState = .idle
        self.podLogDrawer = nil
        self.eventDiagnosis = nil
        self.activePodLogSession = nil
        self.healthShiftAlertTracker = HealthShiftAlertTracker()
        self.healthShiftAlertSettingsRequestGate = HealthShiftAlertSettingsRequestGate()

        self.k9sHandoffCoordinator.onStateChange = { [weak self] state in
            self?.k9sHandoffState = state
        }
        resetK9sHandoffStateForCurrentDisplay()

        if runtimeState.isShowingSetup {
            loadContextsIfNeeded()

            if let selectedContext = runtimeState.targetContextToLoad {
                loadWatchTargets(for: selectedContext)
            }
        } else {
            refreshNow()
            startRefreshLoopIfConfigured()
        }

        startNetworkMonitoring()
    }

    deinit {
        refreshLoopTask?.cancel()
        freshnessTimerTask?.cancel()
        watchTargetLoadTask?.cancel()
        networkRecoveryTask?.cancel()
        podLogStreamTask?.cancel()
        podDiagnosisTask?.cancel()
        eventDiagnosisTask?.cancel()
        networkReachability.stopMonitoring()
    }

    var isEditingExistingConfiguration: Bool {
        !config.needsSetup
    }

    var contextSelectorContexts: [String] {
        runtimeState.contextSelectorContexts
    }

    func refreshNow() {
        guard isNetworkAvailable else { return }
        performRefresh(queueIfBusy: false)
    }

    private func performRefresh(queueIfBusy: Bool) {
        updateFreshnessDisplay()

        guard let ticket = refreshGate.begin(config: config) else {
            if queueIfBusy {
                refreshGate.requestPendingRefresh()
            }
            return
        }

        isRefreshing = true
        let config = config
        let previousSnapshot = snapshot
        let refreshCoordinator = refreshCoordinator

        Task {
            defer {
                let shouldRunPendingRefresh = refreshGate.finishAndConsumePendingRefresh()
                isRefreshing = false

                if shouldRunPendingRefresh {
                    performRefresh(queueIfBusy: false)
                }
            }

            let result = await Task.detached(priority: .userInitiated) {
                refreshCoordinator.refresh(config: config, previousSnapshot: previousSnapshot, now: Date())
            }.value

            guard refreshGate.shouldApply(ticket, currentConfig: self.config) else {
                return
            }

            applyRefreshResult(result)
        }
    }

    func openSetup() {
        k9sHandoffCoordinator.clear()
        runtimeState.openSetup()
        runtimeState.applyStartAtLoginState(startAtLoginSettings.currentState())
        publishRuntimeState()
        loadContextsIfNeeded()

        if let selectedContext = runtimeState.targetContextToLoad {
            loadWatchTargets(for: selectedContext)
        }
    }

    func prepareSettings() {
        k9sHandoffCoordinator.clear()
        healthShiftAlertSettingsRequestGate.invalidate()
        runtimeState.prepareSettings(config: config)
        runtimeState.applyStartAtLoginState(startAtLoginSettings.currentState())
        publishRuntimeState()
        loadContextsForSettings()

        if let selectedContext = runtimeState.setupState.selectedContext {
            loadWatchTargets(for: selectedContext)
        }
    }

    @discardableResult
    func completeSetup() -> Bool {
        k9sHandoffCoordinator.clear()
        guard let completedConfig = runtimeState.completedConfig() else {
            return false
        }

        do {
            try configStore.save(completedConfig)

            if runtimeState.setupState.aiDiagnosticAssistant.hasAPIKeyDraft {
                do {
                    try aiCredentialStore.saveAPIKey(
                        runtimeState.setupState.aiDiagnosticAssistant.apiKeyDraft,
                        for: completedConfig.aiDiagnosticAssistant.provider
                    )
                } catch {
                    runtimeState.markConfigurationSaveFailed(Self.aiCredentialSaveFailureMessage)
                    publishRuntimeState()
                    return false
                }
            }

            runtimeState.setupState.updateAIDiagnosticAssistantAPIKeyDraft("")
            closePodLogDrawer()
            config = completedConfig
            activeContextName = completedConfig.selectedContext
            healthShiftAlertSettingsRequestGate.invalidate()
            invalidateRefreshState(clearSnapshot: true)
            display = Self.initialDisplay(for: config, now: Date())
            runtimeState.completeSetupSaved()
            publishRuntimeState()
            if isNetworkAvailable {
                performRefresh(queueIfBusy: true)
            }
            startRefreshLoopIfConfigured()
            return true
        } catch {
            runtimeState.markConfigurationSaveFailed(SetupFlowState.settingsSaveFailureMessage)
            publishRuntimeState()
            return false
        }
    }

    func setStartAtLoginEnabled(_ isEnabled: Bool) {
        let coordinator = startAtLoginSettings
        Task {
            let updatedState = await Task.detached(priority: .userInitiated) {
                coordinator.setEnabled(isEnabled)
            }.value

            runtimeState.applyStartAtLoginState(updatedState)
            publishRuntimeState()
        }
    }

    func setHealthShiftAlertsEnabled(_ isEnabled: Bool) {
        let requestToken = healthShiftAlertSettingsRequestGate.beginRequest()

        guard isEnabled else {
            runtimeState.applyHealthShiftAlertsState(HealthShiftAlertsState(isEnabled: false))
            publishRuntimeState()
            return
        }

        let coordinator = healthShiftAlertSettings
        Task {
            let updatedState = await coordinator.setEnabled(true)
            guard healthShiftAlertSettingsRequestGate.accepts(requestToken) else {
                return
            }

            runtimeState.applyHealthShiftAlertsState(updatedState)
            publishRuntimeState()
        }
    }

    func addKubeconfigPaths(_ paths: [String]) {
        runtimeState.setupState.appendKubeconfigPaths(paths)
        publishRuntimeState()
    }

    func removeKubeconfigPath(at index: Int) {
        runtimeState.setupState.removeKubeconfigPath(at: index)
        publishRuntimeState()
    }

    func moveKubeconfigPathUp(at index: Int) {
        runtimeState.setupState.moveKubeconfigPathUp(at: index)
        publishRuntimeState()
    }

    func moveKubeconfigPathDown(at index: Int) {
        runtimeState.setupState.moveKubeconfigPathDown(at: index)
        publishRuntimeState()
    }

    func updateAIProvider(_ provider: AIProvider) {
        runtimeState.setupState.updateAIDiagnosticAssistant(provider: provider)
        publishRuntimeState()
    }

    func updateAIModelID(_ modelID: String) {
        runtimeState.setupState.updateAIDiagnosticAssistant(modelID: modelID)
        publishRuntimeState()
    }

    func updateAIBaseURL(_ baseURL: String) {
        runtimeState.setupState.updateAIDiagnosticAssistant(baseURL: baseURL)
        publishRuntimeState()
    }

    func updateAIAPIKeyDraft(_ draft: String) {
        runtimeState.setupState.updateAIDiagnosticAssistantAPIKeyDraft(draft)
        publishRuntimeState()
    }

    func testAIConnection() {
        guard let tester = aiConnectionTester else {
            return
        }

        let provider = runtimeState.setupState.aiDiagnosticAssistant.config.provider
        let config = runtimeState.setupState.aiDiagnosticAssistant.config
        let draft = runtimeState.setupState.aiDiagnosticAssistant.hasAPIKeyDraft
            ? runtimeState.setupState.aiDiagnosticAssistant.apiKeyDraft
            : nil

        runtimeState.setupState.applyAIDiagnosticAssistantTestConnectionResult(nil)
        publishRuntimeState()

        Task {
            let result = await tester.testConnection(config: config, provider: provider, apiKeyOverride: draft)
            runtimeState.setupState.applyAIDiagnosticAssistantTestConnectionResult(result)
            publishRuntimeState()
        }
    }

    func selectSetupContext(_ context: String?) {
        k9sHandoffCoordinator.clear()
        watchTargetLoadTask?.cancel()
        watchTargetLoadTask = nil

        let contextToLoad = runtimeState.selectContext(context)
        publishRuntimeState()

        contextToLoad.map(loadWatchTargets)
    }

    func selectAppSettingsTab() {
        k9sHandoffCoordinator.clear()
        runtimeState.selectAppSettingsTab()
        publishRuntimeState()
    }

    func selectAppPage(_ page: SettingsTabSelection) {
        k9sHandoffCoordinator.clear()
        runtimeState.selectAppPage(page)
        publishRuntimeState()
    }

    func refreshContextSelectorContexts() {
        loadContexts()
    }

    func selectMenuContext(_ context: String) {
        guard context != config.selectedContext else {
            return
        }

        closePodLogDrawer()
        k9sHandoffCoordinator.clear()
        watchTargetLoadTask?.cancel()
        watchTargetLoadTask = nil

        let updatedConfig = config.selectingContext(context)

        do {
            try configStore.save(updatedConfig)
        } catch {
            display = HealthEvaluator().evaluate(
                snapshot: nil,
                previousSnapshot: snapshot,
                failure: RefreshFailure(reason: SetupFlowState.settingsSaveFailureMessage),
                now: Date(),
                staleAfterSeconds: config.refreshIntervalSeconds * 2
            )
            staleReason = display.staleBanner?.reason
            return
        }

        config = updatedConfig
        activeContextName = updatedConfig.selectedContext
        healthShiftAlertSettingsRequestGate.invalidate()
        invalidateRefreshState(clearSnapshot: true)
        display = Self.initialDisplay(for: updatedConfig, now: Date())
        runtimeState.applyActiveConfig(updatedConfig)
        publishRuntimeState()
        startRefreshLoopIfConfigured()

        if let selectedContext = runtimeState.targetContextToLoad {
            loadWatchTargets(for: selectedContext)
        } else if isNetworkAvailable {
            performRefresh(queueIfBusy: true)
        }
    }

    func retryWatchTargetLoad() {
        k9sHandoffCoordinator.clear()
        guard let selectedContext = runtimeState.targetContextToLoad else {
            runtimeState.setupState.targetLoadingState = .idle
            publishRuntimeState()
            return
        }

        loadWatchTargets(for: selectedContext)
    }

    private static var defaultConfigDirectory: URL {
        (FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("Kubebar", isDirectory: true)
    }

    private static func initialDisplay(for config: AppConfig, now: Date) -> MenuDisplayModel {
        let reason = config.needsSetup
            ? "Choose a cluster context and watchlist to begin"
            : "Waiting for first refresh"

        return HealthEvaluator().evaluate(
            snapshot: nil,
            previousSnapshot: nil,
            failure: RefreshFailure(reason: reason),
            now: now
        )
    }

    private func loadContextsIfNeeded() {
        guard runtimeState.shouldLoadContexts else {
            return
        }

        loadContexts()
    }

    private func loadContextsForSettings() {
        loadContexts()
    }

    private func loadContexts() {
        let contextCatalog = contextCatalog
        let config = previewConfigForDiscovery()

        Task {
            let contexts = await Task.detached(priority: .userInitiated) {
                (try? contextCatalog.listContexts(config: config)) ?? []
            }.value

            runtimeState.replaceAvailableContexts(contexts)
            publishRuntimeState()
        }
    }

    private func loadWatchTargets(for context: String) {
        let watchTargetCatalog = watchTargetCatalog
        let config = previewConfigForDiscovery()
        watchTargetLoadTask?.cancel()
        runtimeState.beginTargetLoading(for: context)
        publishRuntimeState()

        watchTargetLoadTask = Task {
            let result: Result<WatchlistCandidates, Error>

            do {
                let candidates = try await watchTargetCatalog.listCandidates(config: config, contextName: context)
                try Task.checkCancellation()
                result = .success(candidates)
            } catch is CancellationError {
                return
            } catch {
                result = .failure(error)
            }

            guard !Task.isCancelled else {
                return
            }

            switch result {
            case let .success(candidates):
                runtimeState.applyTargetLoadSuccess(candidates, for: context)
            case let .failure(error):
                runtimeState.applyTargetLoadFailure(Self.failureReason(from: error), for: context)
            }

            publishRuntimeState()
        }
    }

    private func previewConfigForDiscovery() -> AppConfig {
        var preview = config
        preview = AppConfig(
            selectedContext: preview.selectedContext,
            watchlistsByContext: preview.watchlistsByContext,
            refreshIntervalSeconds: runtimeState.setupState.refreshCadence.seconds,
            healthShiftAlertsEnabled: runtimeState.setupState.healthShiftAlerts.isEnabled,
            kubeconfigPaths: runtimeState.setupState.kubeconfigPaths
        )
        return preview
    }

    private func startRefreshLoopIfConfigured() {
        refreshLoopTask?.cancel()
        refreshLoopTask = nil

        guard !config.needsSetup else {
            return
        }

        let intervalNanoseconds = UInt64(config.refreshCadence.seconds) * 1_000_000_000

        refreshLoopTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: intervalNanoseconds)
                } catch {
                    return
                }

                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    // Guard here as a safety net; refreshNow() also checks isNetworkAvailable.
                    guard self?.isNetworkAvailable == true else { return }
                    self?.refreshNow()
                }
            }
        }
    }

    // MARK: - Network Reachability

    private func startNetworkMonitoring() {
        networkReachability.startMonitoring { [weak self] isAvailable in
            self?.handleNetworkChange(isAvailable: isAvailable)
        }
    }

    private func handleNetworkChange(isAvailable: Bool) {
        let wasAvailable = isNetworkAvailable
        isNetworkAvailable = isAvailable

        if isAvailable && !wasAvailable {
            // Network recovered: debounce 2 s then refresh and restart the loop.
            scheduleNetworkRecoveryRefresh()
        } else if !isAvailable {
            // Network lost: cancel the debounce task and the refresh loop.
            // The freshness timer keeps running so stale data ages correctly.
            networkRecoveryTask?.cancel()
            networkRecoveryTask = nil
            refreshLoopTask?.cancel()
            refreshLoopTask = nil
        }
    }

    private func scheduleNetworkRecoveryRefresh() {
        networkRecoveryTask?.cancel()

        networkRecoveryTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: Self.networkRecoveryDebounceNanoseconds)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self, self.isNetworkAvailable else { return }
                self.performRefresh(queueIfBusy: false)
                self.startRefreshLoopIfConfigured()
            }
        }
    }

    private func invalidateRefreshState(clearSnapshot: Bool) {
        refreshGate.invalidate()
        freshnessTimerTask?.cancel()
        freshnessTimerTask = nil
        staleReason = nil
        k9sHandoffCoordinator.clear()
        healthShiftAlertTracker.reset()
        eventDiagnosisTask?.cancel()
        eventDiagnosisTask = nil
        eventDiagnosis = nil

        if clearSnapshot {
            snapshot = nil
        }
    }

    private func applyRefreshResult(_ result: RefreshResult) {
        snapshot = result.snapshot
        display = result.display
        let alert = healthShiftAlertTracker.record(result.display)
        staleReason = result.display.staleBanner?.reason
        resetK9sHandoffStateForCurrentDisplay()
        k9sHandoffState = k9sHandoffCoordinator.state
        deliverHealthShiftAlertIfNeeded(alert)
        scheduleFreshnessTimer()
    }

    private func deliverHealthShiftAlertIfNeeded(_ alert: HealthShiftAlert?) {
        guard config.healthShiftAlertsEnabled, let alert else {
            return
        }

        let notifier = healthShiftAlertNotifier
        Task {
            await notifier.deliver(alert)
        }
    }

    private func updateFreshnessDisplay(now: Date = Date()) {
        guard let snapshot else {
            return
        }

        let staleAfterSeconds = config.refreshIntervalSeconds * 2

        if let staleReason, staleReason != "Last refresh is too old" {
            display = HealthEvaluator().evaluate(
                snapshot: nil,
                previousSnapshot: snapshot,
                failure: RefreshFailure(reason: staleReason),
                now: now,
                staleAfterSeconds: staleAfterSeconds
            )
        } else {
            display = HealthEvaluator().evaluate(
                snapshot: snapshot,
                now: now,
                staleAfterSeconds: staleAfterSeconds
            )
        }

        staleReason = display.staleBanner?.reason
        resetK9sHandoffStateForCurrentDisplay()
        k9sHandoffState = k9sHandoffCoordinator.state
    }

    func openK9sHandoff() {
        k9sHandoffCoordinator.open(for: display.overview.k9sHandoff)
    }

    func openK9sHandoff(_ handoff: OverviewK9sHandoff) {
        k9sHandoffCoordinator.open(for: handoff)
    }

    func openPodLogDrawer(for target: PodLogTarget) {
        closePodLogDrawer()

        let request = PodLogStreamRequest(target: target, config: config)
        let streamer = podLogStreamer
        let session = PodLogStreamSession(target: target)

        podLogSearchQuery = ""
        activePodLogSession = session
        podLogDrawer = PodLogDrawerPresentation(
            session: session,
            target: target,
            state: .loading,
            buffer: PodLogBuffer(),
            aiDiagnosis: .idle
        )

        podLogStreamTask = Task { [weak self] in
            do {
                for try await chunk in streamer.streamLogs(for: request) {
                    try Task.checkCancellation()
                    await MainActor.run {
                        self?.appendPodLogChunk(chunk, for: target, sessionID: session.id)
                    }
                }

                await MainActor.run {
                    self?.finishPodLogStream(for: target, sessionID: session.id)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.cancelPodLogStream(for: target, sessionID: session.id)
                }
            } catch {
                await MainActor.run {
                    self?.failPodLogStream(error, for: target, sessionID: session.id)
                }
            }
        }
    }

    func closePodLogDrawer() {
        podLogStreamTask?.cancel()
        podDiagnosisTask?.cancel()
        podLogStreamTask = nil
        podDiagnosisTask = nil
        activePodLogSession = nil
        podLogDrawer = nil
        podLogSearchQuery = ""
    }

    func copyCurrentPodLogs() {
        guard let text = podLogDrawer?.visibleText, !text.isEmpty else {
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func diagnoseCurrentPodWithAI() {
        guard var drawer = podLogDrawer else {
            return
        }

        guard let requester = aiPodDiagnosticRequester else {
            drawer.aiDiagnosis = .failed("AI diagnosis is unavailable.")
            podLogDrawer = drawer
            return
        }

        podDiagnosisTask?.cancel()

        let target = drawer.target
        let request = PodDiagnosticLogReadRequest(target: target, config: config)
        let logReader = podDiagnosticLogReader
        let provider = config.aiDiagnosticAssistant.provider
        let aiConfig = config.aiDiagnosticAssistant
        let contextBase = podDiagnosticContextBase(for: target)

        drawer.aiDiagnosis = .loading
        podLogDrawer = drawer

        podDiagnosisTask = Task { [weak self] in
            do {
                let logLines = try await logReader.readLogs(for: request)
                try Task.checkCancellation()
                let context = AIPodDiagnosticContext(
                    target: target,
                    podStatus: contextBase.podStatus,
                    warnings: contextBase.warnings,
                    logLines: logLines,
                    isStale: contextBase.isStale
                )
                let result = await requester.diagnose(context: context, config: aiConfig, provider: provider)

                await MainActor.run {
                    self?.applyAIPodDiagnosticResult(result, for: target)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.clearAIPodDiagnosisTask(for: target)
                }
            } catch {
                await MainActor.run {
                    self?.applyAIPodDiagnosticResult(
                        .failed("Could not read recent logs: \(Self.failureReason(from: error))"),
                        for: target
                    )
                }
            }
        }
    }

    func dismissWarningEventDiagnosis() {
        eventDiagnosisTask?.cancel()
        eventDiagnosisTask = nil
        eventDiagnosis = nil
    }

    func diagnoseWarningEventWithAI(_ target: WarningEventDiagnosticTarget) {
        guard let requester = aiEventDiagnosticRequester else {
            eventDiagnosis = EventDiagnosisPresentation(target: target, state: .failed("AI diagnosis is unavailable."))
            return
        }

        eventDiagnosisTask?.cancel()

        let request = WarningEventDiagnosticReadRequest(target: target, config: config)
        let reader = warningEventDiagnosticReader
        let provider = config.aiDiagnosticAssistant.provider
        let aiConfig = config.aiDiagnosticAssistant
        let isStale = display.state == .stale

        eventDiagnosis = EventDiagnosisPresentation(target: target, state: .loading)

        eventDiagnosisTask = Task { [weak self] in
            do {
                let records = try await reader.readEvents(for: request)
                try Task.checkCancellation()
                let context = AIEventDiagnosticContext(
                    target: target,
                    events: records.map(AIEventDiagnosticEvent.init(record:)),
                    isStale: isStale
                )
                let result = await requester.diagnose(context: context, config: aiConfig, provider: provider)

                await MainActor.run {
                    self?.applyAIEventDiagnosticResult(result, for: target)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.clearAIEventDiagnosisTask(for: target)
                }
            } catch {
                await MainActor.run {
                    self?.applyAIEventDiagnosticResult(
                        .failed("Could not read recent warning events: \(Self.failureReason(from: error))"),
                        for: target
                    )
                }
            }
        }
    }

    private func resetK9sHandoffStateForCurrentDisplay() {
        guard let target = k9sHandoffCoordinator.state.target else {
            return
        }

        let availableTarget = availableK9sHandoffs.first { $0 == target }
        k9sHandoffCoordinator.resetIfTargetUnavailable(availableTarget)
    }

    private var availableK9sHandoffs: [OverviewK9sHandoff] {
        display.k9sHandoffs
    }

    private func appendPodLogChunk(_ chunk: String, for target: PodLogTarget, sessionID: UUID) {
        guard var drawer = currentPodLogDrawer(for: target, sessionID: sessionID) else {
            return
        }

        drawer.buffer.append(chunk)
        drawer.state = drawer.buffer.lines.isEmpty ? .empty : .live
        podLogDrawer = drawer
    }

    private func finishPodLogStream(for target: PodLogTarget, sessionID: UUID) {
        guard var drawer = currentPodLogDrawer(for: target, sessionID: sessionID) else {
            return
        }

        drawer.state = drawer.buffer.lines.isEmpty ? .empty : .ended
        podLogDrawer = drawer
        podLogStreamTask = nil
        activePodLogSession = nil
    }

    private func cancelPodLogStream(for target: PodLogTarget, sessionID: UUID) {
        guard var drawer = currentPodLogDrawer(for: target, sessionID: sessionID) else {
            return
        }

        drawer.state = .cancelled
        podLogDrawer = drawer
        podLogStreamTask = nil
        activePodLogSession = nil
    }

    private func failPodLogStream(_ error: Error, for target: PodLogTarget, sessionID: UUID) {
        guard var drawer = currentPodLogDrawer(for: target, sessionID: sessionID) else {
            return
        }

        drawer.state = .failed(Self.failureReason(from: error))
        podLogDrawer = drawer
        podLogStreamTask = nil
        activePodLogSession = nil
    }

    private func currentPodLogDrawer(for target: PodLogTarget, sessionID: UUID) -> PodLogDrawerPresentation? {
        guard let drawer = podLogDrawer,
              drawer.session.accepts(id: sessionID, target: target),
              activePodLogSession?.accepts(id: sessionID, target: target) == true
        else {
            return nil
        }

        return drawer
    }

    private func applyAIPodDiagnosticResult(_ result: AIPodDiagnosticResult, for target: PodLogTarget) {
        guard var drawer = podLogDrawer, drawer.target == target else {
            return
        }

        switch result {
        case let .success(markdown):
            drawer.aiDiagnosis = .success(markdown: markdown)
        case let .failed(message):
            drawer.aiDiagnosis = .failed(message)
        }
        podLogDrawer = drawer
        podDiagnosisTask = nil
    }

    private func clearAIPodDiagnosisTask(for target: PodLogTarget) {
        guard podLogDrawer?.target == target else {
            return
        }

        podDiagnosisTask = nil
    }

    private func applyAIEventDiagnosticResult(_ result: AIEventDiagnosticResult, for target: WarningEventDiagnosticTarget) {
        guard var presentation = eventDiagnosis, presentation.target == target else {
            return
        }

        switch result {
        case let .success(markdown):
            presentation.state = .success(markdown: markdown)
        case let .failed(message):
            presentation.state = .failed(message)
        }
        eventDiagnosis = presentation
        eventDiagnosisTask = nil
    }

    private func clearAIEventDiagnosisTask(for target: WarningEventDiagnosticTarget) {
        guard eventDiagnosis?.target == target else {
            return
        }

        eventDiagnosisTask = nil
    }

    private struct AIPodDiagnosticContextBase {
        let podStatus: AIPodStatusContext
        let warnings: [AIPodWarningContext]
        let isStale: Bool
    }

    private func podDiagnosticContextBase(for target: PodLogTarget) -> AIPodDiagnosticContextBase {
        let pod = podItem(for: target)
        return AIPodDiagnosticContextBase(
            podStatus: AIPodStatusContext(
                state: pod?.state.label ?? "Unknown",
                ready: pod?.readyLabel ?? "unknown",
                reason: pod?.issueText,
                detail: pod?.helpText
            ),
            warnings: relatedWarnings(for: target),
            isStale: display.state == .stale
        )
    }

    private func podItem(for target: PodLogTarget) -> PodItemDisplay? {
        display.podTab.sections
            .first { $0.namespace == target.namespace }?
            .rows
            .first { $0.name == target.podName }
    }

    private func relatedWarnings(for target: PodLogTarget) -> [AIPodWarningContext] {
        display.eventsTab.rows
            .filter { row in
                row.location.contains(target.podName) ||
                    row.helpText.contains(target.podName) ||
                    row.accessibilityLabel.contains(target.podName)
            }
            .prefix(3)
            .map { row in
                AIPodWarningContext(
                    reason: row.reason,
                    location: row.location,
                    age: row.age,
                    message: row.fullMessage
                )
            }
    }

    private func scheduleFreshnessTimer(now: Date = Date()) {
        freshnessTimerTask?.cancel()
        freshnessTimerTask = nil

        guard let snapshot, !config.needsSetup else {
            return
        }

        let staleAfterSeconds = config.refreshIntervalSeconds * 2
        let delaySeconds = FreshnessDisplaySchedule.nextUpdateDelaySeconds(
            capturedAt: snapshot.capturedAt,
            now: now,
            staleAfterSeconds: staleAfterSeconds
        )
        let delayNanoseconds = UInt64(delaySeconds) * 1_000_000_000

        freshnessTimerTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: delayNanoseconds)
            } catch {
                return
            }

            await MainActor.run {
                self?.handleFreshnessTimerFired()
            }
        }
    }

    private func handleFreshnessTimerFired() {
        updateFreshnessDisplay()
        scheduleFreshnessTimer()
    }

    private static func failureReason(from error: Error) -> String {
        if case let KubectlCommandError.failed(reason) = error {
            return reason
        }

        return error.localizedDescription
    }

    private func publishRuntimeState() {
        isPublishingRuntimeState = true
        setupState = runtimeState.setupState
        isShowingSetup = runtimeState.isShowingSetup
        isPublishingRuntimeState = false
    }
}
