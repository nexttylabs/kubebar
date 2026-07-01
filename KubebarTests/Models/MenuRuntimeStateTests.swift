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

    @Test("menu selector contexts include only local available contexts")
    func menuSelectorContextsIncludeOnlyLocalAvailableContexts() {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "default",
                watchlistsByContext: [
                    "default": [.namespace("api")]
                ]
            )
        )

        state.setupState.availableContexts = ["prod", "stage"]

        #expect(state.contextSelectorContexts == ["prod", "stage"])
    }

    @Test("applying configured context returns menu surface and matching watchlist")
    func applyingConfiguredContextReturnsMenuSurfaceAndMatchingWatchlist() {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchlistsByContext: [
                    "prod": [.namespace("api")],
                    "stage": [.namespace("web")]
                ]
            )
        )
        state.setupState.availableContexts = ["prod", "stage"]

        state.applyActiveConfig(
            AppConfig(
                selectedContext: "stage",
                watchlistsByContext: [
                    "default": [.namespace("old")],
                    "prod": [.namespace("api")],
                    "stage": [.namespace("web")]
                ]
            )
        )

        #expect(!state.isShowingSetup)
        #expect(state.setupState.selectedContext == "stage")
        #expect(state.setupState.watchlist.isSelected(.namespace("web")))
        #expect(state.contextSelectorContexts == ["prod", "stage"])
    }

    @Test("applying context without watchlist shows configuration required")
    func applyingContextWithoutWatchlistShowsConfigurationRequired() {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchlistsByContext: [
                    "prod": [.namespace("api")]
                ]
            )
        )
        state.setupState.availableContexts = ["prod", "stage"]

        state.applyActiveConfig(
            AppConfig(
                selectedContext: "stage",
                watchlistsByContext: [
                    "default": [.namespace("old")],
                    "prod": [.namespace("api")]
                ]
            )
        )

        #expect(state.isShowingSetup)
        #expect(state.shouldLoadContexts)
        #expect(state.targetContextToLoad == "stage")
        #expect(state.setupState.watchlist.selectedTargets.isEmpty)
        #expect(state.contextSelectorContexts == ["prod", "stage"])
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
            healthShiftAlertsEnabled: true,
            kubeconfigPaths: [
                "/Users/derek/.kube/config",
                "/Users/derek/.kube/prod.yaml"
            ]
        )
        var state = MenuRuntimeState(config: config)

        state.prepareSettings(config: config)

        #expect(state.setupState.selectedContext == "prod")
        #expect(state.setupState.watchlist.selectedTargets == [.namespace("api")])
        #expect(state.setupState.refreshCadence == .twoMinutes)
        #expect(state.setupState.healthShiftAlerts.isEnabled)
        #expect(state.setupState.kubeconfigPaths == [
            "/Users/derek/.kube/config",
            "/Users/derek/.kube/prod.yaml"
        ])
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

    @Test("selecting settings context switches to that context watchlist")
    func selectingSettingsContextSwitchesToThatContextWatchlist() {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchlistsByContext: [
                    "prod": [.namespace("api")],
                    "stage": [.namespace("web")]
                ]
            )
        )

        let contextToLoad = state.selectContext("stage")

        #expect(contextToLoad == "stage")
        #expect(state.setupState.selectedContext == "stage")
        #expect(state.setupState.watchlist.isSelected(.namespace("web")))
        #expect(!state.setupState.watchlist.isSelected(.namespace("api")))
    }

    @Test("settings context selections are preserved across tabs")
    func settingsContextSelectionsArePreservedAcrossTabs() {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchlistsByContext: [
                    "prod": [.namespace("api")],
                    "stage": [.namespace("web")]
                ]
            )
        )

        _ = state.selectContext("stage")
        state.setupState.watchlist.toggle(.namespace("ops"))
        _ = state.selectContext("prod")

        #expect(state.setupState.watchlist.isSelected(.namespace("api")))

        _ = state.selectContext("stage")

        #expect(state.setupState.watchlist.isSelected(.namespace("web")))
        #expect(state.setupState.watchlist.isSelected(.namespace("ops")))
    }

    @Test("selecting app settings tab preserves edits and clears message")
    func selectingAppSettingsTabPreservesEditsAndClearsMessage() {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchlistsByContext: [
                    "prod": [.namespace("api")],
                    "stage": [.namespace("web")]
                ]
            )
        )

        _ = state.selectContext("stage")
        state.setupState.watchlist.toggle(.namespace("ops"))
        state.setupState.configurationMessage = "Could not save settings."
        state.selectAppSettingsTab()

        #expect(state.setupState.selectedSettingsTab == .appSettings)
        #expect(state.setupState.configurationMessage == nil)
        #expect(state.setupState.currentWatchlistsByContext()["stage"]?.isSelected(.namespace("web")) == true)
        #expect(state.setupState.currentWatchlistsByContext()["stage"]?.isSelected(.namespace("ops")) == true)
    }

    @Test("failed target load preserves per-context selections")
    func failedTargetLoadPreservesPerContextSelections() {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchlistsByContext: [
                    "prod": [.namespace("api")],
                    "stage": [.namespace("web")]
                ]
            )
        )

        _ = state.selectContext("stage")
        state.applyTargetLoadFailure("forbidden", for: "stage")

        #expect(state.setupState.watchlist.isSelected(.namespace("web")))
        #expect(state.setupState.targetLoadingState == .failed("forbidden"))

        _ = state.selectContext("prod")

        #expect(state.setupState.watchlist.isSelected(.namespace("api")))
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
        #expect(config.watchlistsByContext["prod"]?.map(\.displayTitle) == ["api"])
        #expect(config.refreshIntervalSeconds == 120)
        #expect(config.kubeconfigPaths.isEmpty)
    }

    @Test("completed config saves per-context namespace watchlists")
    func completedConfigSavesPerContextNamespaceWatchlists() throws {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchlistsByContext: [
                    "prod": [.namespace("api")],
                    "stage": [.namespace("web")]
                ]
            )
        )

        _ = state.selectContext("stage")
        state.setupState.watchlist.toggle(.namespace("ops"))

        let config = try #require(state.completedConfig())

        #expect(config.selectedContext == "stage")
        #expect(config.watchlistsByContext["prod"]?.map(\.displayTitle) == ["api"])
        #expect(config.watchlistsByContext["stage"]?.map(\.displayTitle) == ["ops", "web"])
        #expect(config.watchTargets.map(\.displayTitle) == ["ops", "web"])
    }

    @Test("completed config from app settings preserves active context")
    func completedConfigFromAppSettingsPreservesActiveContext() throws {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchlistsByContext: [
                    "prod": [.namespace("api")],
                    "stage": [.namespace("web")]
                ]
            )
        )

        _ = state.selectContext("stage")
        state.setupState.watchlist.toggle(.namespace("ops"))
        state.selectAppSettingsTab()

        let config = try #require(state.completedConfig())

        #expect(config.selectedContext == "prod")
        #expect(config.watchlistsByContext["prod"]?.map(\.displayTitle) == ["api"])
        #expect(config.watchlistsByContext["stage"]?.map(\.displayTitle) == ["ops", "web"])
        #expect(config.watchTargets.map(\.displayTitle) == ["api"])
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

    @Test("completed config preserves kubeconfig path order")
    func completedConfigPreservesKubeconfigPathOrder() throws {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchTargets: [.namespace("api")],
                kubeconfigPaths: [
                    "/Users/derek/.kube/config",
                    "/Users/derek/.kube/team.yaml"
                ]
            )
        )

        state.setupState.kubeconfigPaths = [
            "/Users/derek/.kube/override.yaml",
            "/Users/derek/.kube/config"
        ]

        let config = try #require(state.completedConfig())

        #expect(config.kubeconfigPaths == [
            "/Users/derek/.kube/override.yaml",
            "/Users/derek/.kube/config"
        ])
    }

    @Test("prepare settings exposes saved ai diagnostic assistant config")
    func prepareSettingsExposesSavedAIDiagnosticAssistantConfig() {
        let savedConfig = AppConfig(
            selectedContext: "prod",
            watchTargets: [.namespace("api")],
            aiDiagnosticAssistant: AIDiagnosticAssistantConfig(
                provider: .anthropic,
                modelID: "claude-3",
                baseURL: nil
            )
        )
        let state = MenuRuntimeState(config: savedConfig)

        #expect(state.setupState.aiDiagnosticAssistant.config == savedConfig.aiDiagnosticAssistant)
    }

    @Test("completed config preserves ai diagnostic assistant config")
    func completedConfigPreservesAIDiagnosticAssistantConfig() throws {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchTargets: [.namespace("api")],
                aiDiagnosticAssistant: AIDiagnosticAssistantConfig(
                    provider: .openAICompatible,
                    modelID: "gpt-4o-mini",
                    baseURL: "https://example.test/v1"
                )
            )
        )
        state.setupState.aiDiagnosticAssistant.config.modelID = "gpt-4o"

        let config = try #require(state.completedConfig())

        #expect(config.aiDiagnosticAssistant.provider == .openAICompatible)
        #expect(config.aiDiagnosticAssistant.modelID == "gpt-4o")
        #expect(config.aiDiagnosticAssistant.baseURL == "https://example.test/v1")
    }

    @Test("changed ai diagnostic assistant config marks settings unsaved")
    func changedAIDiagnosticAssistantConfigMarksSettingsUnsaved() {
        let savedConfig = AppConfig(
            selectedContext: "prod",
            watchTargets: [.namespace("api")],
            aiDiagnosticAssistant: AIDiagnosticAssistantConfig(
                provider: .openAI,
                modelID: "gpt-4o-mini",
                baseURL: nil
            )
        )
        var state = MenuRuntimeState(config: savedConfig)
        state.setupState.aiDiagnosticAssistant.config.modelID = "gpt-4o"

        state.prepareSettings(config: savedConfig)

        #expect(state.setupState.aiDiagnosticAssistant.config.modelID == "gpt-4o")
    }

    @Test("replacing available contexts hides missing context tabs without dropping saved watchlists")
    func replacingAvailableContextsHidesMissingContextTabsWithoutDroppingSavedWatchlists() throws {
        var state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchlistsByContext: [
                    "prod": [.namespace("api")],
                    "stage": [.namespace("web")]
                ]
            )
        )

        _ = state.selectContext("stage")
        state.replaceAvailableContexts(["prod"])

        #expect(state.contextSelectorContexts == ["prod"])
        #expect(state.setupState.selectedSettingsTab == .appSettings)

        let config = try #require(state.completedConfig())
        #expect(config.watchlistsByContext["stage"]?.map(\.displayTitle) == ["web"])
    }
}
