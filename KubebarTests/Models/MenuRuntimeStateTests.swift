import Testing
@testable import KubebarCore

@Suite("Menu runtime state")
struct MenuRuntimeStateTests {
    @Test("fresh config starts setup and requests contexts")
    func freshConfigStartsSetupAndRequestsContexts() {
        let state = MenuRuntimeState(config: AppConfig())

        #expect(state.surface == .setup)
        #expect(state.isShowingSetup)
        #expect(state.shouldLoadContexts)
        #expect(state.targetContextToLoad == nil)
    }

    @Test("partial config starts setup and requests target loading")
    func partialConfigStartsSetupAndRequestsTargetLoading() {
        let state = MenuRuntimeState(
            config: AppConfig(selectedContext: "prod", watchTargets: [])
        )

        #expect(state.surface == .setup)
        #expect(state.targetContextToLoad == "prod")
    }

    @Test("configured app starts on menu")
    func configuredAppStartsOnMenu() {
        let state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchTargets: [.namespace("api")]
            )
        )

        #expect(state.surface == .menu)
        #expect(!state.isShowingSetup)
        #expect(!state.shouldLoadContexts)
        #expect(state.targetContextToLoad == nil)
    }

    @Test("opening setup from configured state requests saved context targets")
    func openingSetupFromConfiguredStateRequestsSavedContextTargets() {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchTargets: [.namespace("api")]
            )
        )

        state.openSetup()

        #expect(state.surface == .setup)
        #expect(state.shouldLoadContexts)
        #expect(state.targetContextToLoad == "prod")
    }

    @Test("selecting context clears candidates and requests target load")
    func selectingContextClearsCandidatesAndRequestsTargetLoad() {
        var state = MenuRuntimeState(config: AppConfig())
        state.setupState.watchlist.replaceAvailableTargets(
            WatchlistCandidates(
                namespaces: ["api"],
                workloads: [.workload(namespace: "api", name: "checkout", kind: .deployment)]
            )
        )

        let contextToLoad = state.selectContext("staging")

        #expect(contextToLoad == "staging")
        #expect(state.setupState.selectedContext == "staging")
        #expect(state.setupState.watchlist.availableNamespaces.isEmpty)
        #expect(state.setupState.watchlist.availableWorkloads.isEmpty)
        #expect(state.setupState.targetLoadingState == .loading)
    }

    @Test("failed target load preserves selection")
    func failedTargetLoadPreservesSelection() {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchTargets: [.workload(namespace: "api", name: "checkout", kind: .deployment)]
            )
        )

        state.openSetup()
        state.applyTargetLoadFailure("forbidden", for: "prod")

        #expect(state.setupState.selectedContext == "prod")
        #expect(state.setupState.watchlist.isSelected(.workload(namespace: "api", name: "checkout", kind: .deployment)))
        #expect(state.setupState.targetLoadingState == .failed("forbidden"))
    }

    @Test("completed config sorts targets and preserves refresh interval")
    func completedConfigSortsTargetsAndPreservesRefreshInterval() throws {
        var state = MenuRuntimeState(config: AppConfig())
        _ = state.selectContext("prod")
        state.setupState.watchlist.toggle(.workload(namespace: "z", name: "worker", kind: .deployment))
        state.setupState.watchlist.toggle(.namespace("api"))

        state.selectRefreshCadence(.twoMinutes)

        let config = try #require(state.completedConfig())

        #expect(config.selectedContext == "prod")
        #expect(config.watchTargets.map(\.displayTitle) == ["api", "z/worker"])
        #expect(config.refreshIntervalSeconds == 120)
    }
}
