import Foundation
import SwiftUI
import KubebarCore

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published private(set) var display: MenuDisplayModel
    @Published var setupState: SetupFlowState
    @Published private(set) var isShowingSetup: Bool

    private let configStore: AppConfigStore
    private let refreshCoordinator: RefreshCoordinator
    private let contextCatalog: ContextCatalog
    private let watchTargetCatalog: any WatchTargetCataloging
    private var config: AppConfig
    private var snapshot: ClusterSnapshot?

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
        self.setupState = SetupFlowState(
            selectedContext: config.selectedContext,
            watchlist: WatchlistSelectionState(selectedTargets: Set(config.watchTargets))
        )
        self.isShowingSetup = config.needsSetup
        self.display = Self.initialDisplay(for: config, now: now)

        if config.needsSetup {
            loadContexts()

            if let selectedContext = setupState.selectedContext {
                loadWatchTargets(for: selectedContext)
            }
        } else {
            refreshNow()
        }
    }

    func refreshNow() {
        let config = config
        let previousSnapshot = snapshot
        let refreshCoordinator = refreshCoordinator

        Task {
            let result = await Task.detached(priority: .userInitiated) {
                refreshCoordinator.refresh(config: config, previousSnapshot: previousSnapshot, now: Date())
            }.value

            snapshot = result.snapshot
            display = result.display
        }
    }

    func openSetup() {
        isShowingSetup = true
        loadContexts()

        if let selectedContext = setupState.selectedContext {
            loadWatchTargets(for: selectedContext)
        }
    }

    func completeSetup() {
        guard let selectedContext = setupState.selectedContext, !setupState.watchlist.selectedTargets.isEmpty else {
            return
        }

        config = AppConfig(
            selectedContext: selectedContext,
            watchTargets: Array(setupState.watchlist.selectedTargets).sorted { $0.displayTitle < $1.displayTitle },
            refreshIntervalSeconds: config.refreshIntervalSeconds
        )

        do {
            try configStore.save(config)
            isShowingSetup = false
            refreshNow()
        } catch {
            setupState.configurationMessage = "Could not save setup. Try again."
        }
    }

    func selectSetupContext(_ context: String?) {
        setupState.selectedContext = context
        setupState.watchlist.clearAvailableTargets()

        guard let context else {
            setupState.targetLoadingState = .idle
            return
        }

        loadWatchTargets(for: context)
    }

    func retryWatchTargetLoad() {
        guard let selectedContext = setupState.selectedContext else {
            setupState.targetLoadingState = .idle
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

    private func loadContexts() {
        let contextCatalog = contextCatalog

        Task {
            let contexts = await Task.detached(priority: .userInitiated) {
                (try? contextCatalog.listContexts()) ?? []
            }.value

            setupState.availableContexts = contexts
        }
    }

    private func loadWatchTargets(for context: String) {
        let watchTargetCatalog = watchTargetCatalog
        setupState.targetLoadingState = .loading

        Task {
            let result = await Task.detached(priority: .userInitiated) {
                Result {
                    try watchTargetCatalog.listCandidates(contextName: context)
                }
            }.value

            guard setupState.selectedContext == context else {
                return
            }

            switch result {
            case let .success(candidates):
                setupState.watchlist.replaceAvailableTargets(candidates)
                setupState.targetLoadingState = .idle
            case let .failure(error):
                setupState.targetLoadingState = .failed(Self.failureReason(from: error))
            }
        }
    }

    private static func failureReason(from error: Error) -> String {
        if case let KubectlCommandError.failed(reason) = error {
            return reason
        }

        return error.localizedDescription
    }
}
