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

    @Test("preparing settings preserves namespace configuration fields")
    func preparingSettingsPreservesNamespaceConfigurationFields() {
        let config = AppConfig(
            selectedContext: "prod",
            watchTargets: [
                .namespace("api"),
                .workload(namespace: "ops", name: "worker", kind: .deployment)
            ],
            refreshIntervalSeconds: 120,
            healthShiftAlertsEnabled: true
        )
        var state = MenuRuntimeState(config: config)

        state.prepareSettings(config: config)

        #expect(state.setupState.selectedContext == "prod")
        #expect(state.setupState.watchlist.selectedTargets == [.namespace("api")])
        #expect(state.setupState.refreshCadence == .twoMinutes)
        #expect(state.setupState.healthShiftAlerts.isEnabled)
        #expect(state.setupState.configurationMessage == nil)
    }

    @Test("preparing settings does not switch configured menu to setup")
    func preparingSettingsDoesNotSwitchConfiguredMenuToSetup() {
        let config = AppConfig(
            selectedContext: "prod",
            watchTargets: [.namespace("api")]
        )
        var state = MenuRuntimeState(config: config)

        state.prepareSettings(config: config)

        #expect(state.surface == .menu)
        #expect(!state.isShowingSetup)
    }

    @Test("preparing settings preserves unsaved edits")
    func preparingSettingsPreservesUnsavedEdits() {
        let config = AppConfig(
            selectedContext: "prod",
            watchTargets: [.namespace("api")],
            refreshIntervalSeconds: 60
        )
        var state = MenuRuntimeState(config: config)

        _ = state.selectContext("staging")
        state.setupState.watchlist.toggle(.namespace("ops"))
        state.selectRefreshCadence(.twoMinutes)
        state.applyHealthShiftAlertsState(HealthShiftAlertsState(isEnabled: true))

        state.prepareSettings(config: config)

        #expect(state.setupState.selectedContext == "staging")
        #expect(state.setupState.watchlist.isSelected(.namespace("ops")))
        #expect(state.setupState.refreshCadence == .twoMinutes)
        #expect(state.setupState.healthShiftAlerts.isEnabled)
        #expect(state.surface == .menu)
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
                watchTargets: [.namespace("api")]
            )
        )

        state.openSetup()
        state.applyTargetLoadFailure("forbidden", for: "prod")

        #expect(state.setupState.selectedContext == "prod")
        #expect(state.setupState.watchlist.isSelected(.namespace("api")))
        #expect(state.setupState.targetLoadingState == .failed("forbidden"))
    }

    @Test("completed config saves namespaces and preserves refresh interval")
    func completedConfigSavesNamespacesAndPreservesRefreshInterval() throws {
        var state = MenuRuntimeState(config: AppConfig())
        _ = state.selectContext("prod")
        state.setupState.watchlist.toggle(.workload(namespace: "z", name: "worker", kind: .deployment))
        state.setupState.watchlist.toggle(.namespace("api"))

        state.selectRefreshCadence(.twoMinutes)

        let config = try #require(state.completedConfig())

        #expect(config.selectedContext == "prod")
        #expect(config.watchTargets.map(\.displayTitle) == ["api"])
        #expect(config.refreshIntervalSeconds == 120)
    }

    @Test("start at login state does not affect completed config")
    func startAtLoginStateDoesNotAffectCompletedConfig() throws {
        var state = MenuRuntimeState(config: AppConfig())
        _ = state.selectContext("prod")
        state.setupState.watchlist.toggle(.namespace("api"))

        state.applyStartAtLoginState(StartAtLoginState(isEnabled: true))

        let config = try #require(state.completedConfig())
        #expect(config.selectedContext == "prod")
        #expect(config.watchTargets == [.namespace("api")])
        #expect(config.refreshIntervalSeconds == RefreshCadence.default.seconds)
    }

    @Test("completed config saves health shift alert setting")
    func completedConfigSavesHealthShiftAlertSetting() throws {
        var state = MenuRuntimeState(config: AppConfig())
        _ = state.selectContext("prod")
        state.setupState.watchlist.toggle(.namespace("api"))
        state.applyHealthShiftAlertsState(HealthShiftAlertsState(isEnabled: true))

        let config = try #require(state.completedConfig())

        #expect(config.healthShiftAlertsEnabled)
    }
}
