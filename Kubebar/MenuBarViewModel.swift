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
            refreshCadence = setupState.refreshCadence
        }
    }
    @Published private(set) var isShowingSetup: Bool
    @Published private(set) var refreshCadence: RefreshCadence
    @Published private(set) var isRefreshing: Bool

    private let configStore: AppConfigStore
    private let refreshCoordinator: RefreshCoordinator
    private let contextCatalog: ContextCatalog
    private let watchTargetCatalog: any WatchTargetCataloging
    private var config: AppConfig
    private var snapshot: ClusterSnapshot?
    private var runtimeState: MenuRuntimeState
    private var isPublishingRuntimeState: Bool
    private var refreshLoopTask: Task<Void, Never>?
    private var watchTargetLoadTask: Task<Void, Never>?
    private var refreshGate: RefreshGate

    init(
        configStore: AppConfigStore = AppConfigStore(directory: MenuBarViewModel.defaultConfigDirectory),
        refreshCoordinator: RefreshCoordinator = RefreshCoordinator(),
        contextCatalog: ContextCatalog = ContextCatalog(),
        watchTargetCatalog: any WatchTargetCataloging = WatchTargetCatalog(),
        now: Date = Date()
    ) {
        self.configStore = configStore
        self.refreshCoordinator = refreshCoordinator
        self.contextCatalog = contextCatalog
        self.watchTargetCatalog = watchTargetCatalog

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
        self.refreshCadence = runtimeState.setupState.refreshCadence
        self.isRefreshing = false
        self.refreshGate = RefreshGate()
        self.display = Self.initialDisplay(for: config, now: now)

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
        watchTargetLoadTask?.cancel()
    }

    func refreshNow() {
        guard refreshGate.begin() else {
            return
        }

        isRefreshing = true
        let config = config
        let previousSnapshot = snapshot
        let refreshCoordinator = refreshCoordinator

        Task {
            defer {
                refreshGate.finish()
                isRefreshing = false
            }

            let result = await Task.detached(priority: .userInitiated) {
                refreshCoordinator.refresh(config: config, previousSnapshot: previousSnapshot, now: Date())
            }.value

            snapshot = result.snapshot
            display = result.display
        }
    }

    func openSetup() {
        runtimeState.openSetup()
        publishRuntimeState()
        loadContextsIfNeeded()

        if let selectedContext = runtimeState.targetContextToLoad {
            loadWatchTargets(for: selectedContext)
        }
    }

    func completeSetup() {
        guard let completedConfig = runtimeState.completedConfig() else {
            return
        }

        config = completedConfig

        do {
            try configStore.save(config)
            runtimeState.completeSetupSaved()
            publishRuntimeState()
            refreshNow()
            startRefreshLoopIfConfigured()
        } catch {
            runtimeState.markConfigurationSaveFailed("Could not save setup. Try again.")
            publishRuntimeState()
        }
    }

    func selectSetupContext(_ context: String?) {
        watchTargetLoadTask?.cancel()
        watchTargetLoadTask = nil

        let contextToLoad = runtimeState.selectContext(context)
        publishRuntimeState()

        contextToLoad.map(loadWatchTargets)
    }

    func selectRefreshCadence(_ cadence: RefreshCadence) {
        runtimeState.selectRefreshCadence(cadence)
        publishRuntimeState()

        guard !isShowingSetup else {
            return
        }

        config = AppConfig(
            selectedContext: config.selectedContext,
            watchTargets: config.watchTargets,
            refreshIntervalSeconds: cadence.seconds
        )

        do {
            try configStore.save(config)
            startRefreshLoopIfConfigured()
        } catch {
            display = HealthEvaluator().evaluate(
                snapshot: nil,
                previousSnapshot: snapshot,
                failure: RefreshFailure(reason: "Could not save refresh cadence"),
                now: Date()
            )
        }
    }

    func retryWatchTargetLoad() {
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
        refreshCadence = runtimeState.setupState.refreshCadence
        isPublishingRuntimeState = false
    }
}
