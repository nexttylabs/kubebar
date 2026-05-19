import Foundation
import SwiftUI
import KubebarCore

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published private(set) var display: MenuDisplayModel
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
    private var refreshGate: RefreshGate
    private var staleReason: String?
    private let k9sHandoffCoordinator: K9sHandoffCoordinator
    private let startAtLoginSettings: StartAtLoginSettingsCoordinator

    init(
        configStore: AppConfigStore = AppConfigStore(directory: MenuBarViewModel.defaultConfigDirectory),
        refreshCoordinator: RefreshCoordinator = RefreshCoordinator(),
        contextCatalog: ContextCatalog = ContextCatalog(),
        watchTargetCatalog: any WatchTargetCataloging = WatchTargetCatalog(),
        k9sHandoffCoordinator: K9sHandoffCoordinator = K9sHandoffCoordinator(),
        startAtLoginSettings: StartAtLoginSettingsCoordinator = StartAtLoginSettingsCoordinator(
            controller: SystemStartAtLoginController()
        ),
        now: Date = Date()
    ) {
        self.configStore = configStore
        self.refreshCoordinator = refreshCoordinator
        self.contextCatalog = contextCatalog
        self.watchTargetCatalog = watchTargetCatalog
        self.k9sHandoffCoordinator = k9sHandoffCoordinator
        self.startAtLoginSettings = startAtLoginSettings

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
        self.k9sHandoffState = .idle

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
    }

    deinit {
        refreshLoopTask?.cancel()
        freshnessTimerTask?.cancel()
        watchTargetLoadTask?.cancel()
    }

    var isEditingExistingConfiguration: Bool {
        !config.needsSetup
    }

    func refreshNow() {
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

        config = completedConfig

        do {
            try configStore.save(config)
            invalidateRefreshState(clearSnapshot: true)
            display = Self.initialDisplay(for: config, now: Date())
            runtimeState.completeSetupSaved()
            publishRuntimeState()
            performRefresh(queueIfBusy: true)
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

    func selectSetupContext(_ context: String?) {
        k9sHandoffCoordinator.clear()
        watchTargetLoadTask?.cancel()
        watchTargetLoadTask = nil

        let contextToLoad = runtimeState.selectContext(context)
        publishRuntimeState()

        contextToLoad.map(loadWatchTargets)
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

        Task {
            let contexts = await Task.detached(priority: .userInitiated) {
                (try? contextCatalog.listContexts()) ?? []
            }.value

            runtimeState.setupState.availableContexts = contexts
            publishRuntimeState()
        }
    }

    private func loadWatchTargets(for context: String) {
        let watchTargetCatalog = watchTargetCatalog
        watchTargetLoadTask?.cancel()
        runtimeState.beginTargetLoading(for: context)
        publishRuntimeState()

        watchTargetLoadTask = Task {
            let result: Result<WatchlistCandidates, Error>

            do {
                let candidates = try await watchTargetCatalog.listCandidates(contextName: context)
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
                    self?.refreshNow()
                }
            }
        }
    }

    private func invalidateRefreshState(clearSnapshot: Bool) {
        refreshGate.invalidate()
        freshnessTimerTask?.cancel()
        freshnessTimerTask = nil
        staleReason = nil
        k9sHandoffCoordinator.clear()

        if clearSnapshot {
            snapshot = nil
        }
    }

    private func applyRefreshResult(_ result: RefreshResult) {
        snapshot = result.snapshot
        display = result.display
        staleReason = result.display.staleBanner?.reason
        resetK9sHandoffStateForCurrentDisplay()
        k9sHandoffState = k9sHandoffCoordinator.state
        scheduleFreshnessTimer()
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
