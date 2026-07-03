import Testing
@testable import KubebarCore

@Suite("Setup flow state")
struct SetupFlowStateTests {
    @Test("app pages are available in stable order")
    func appPagesAreAvailableInStableOrder() {
        #expect(SetupFlowState.appPages == [.general, .kubernetes, .notifications, .aiAssistant])
    }

    @Test("selecting an app page preserves current context watchlist edits")
    func selectingAnAppPagePreservesCurrentContextWatchlistEdits() {
        var state = SetupFlowState(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")]),
                "stage": WatchlistSelectionState(selectedTargets: [.namespace("web")])
            ]
        )

        state.selectContext("stage")
        state.watchlist.toggle(.namespace("ops"))
        state.selectAppPage(.aiAssistant)

        #expect(state.selectedSettingsTab == .aiAssistant)
        #expect(state.currentWatchlistsByContext()["stage"]?.isSelected(.namespace("web")) == true)
        #expect(state.currentWatchlistsByContext()["stage"]?.isSelected(.namespace("ops")) == true)
    }

    @Test("selecting an app page clears the configuration message")
    func selectingAnAppPageClearsConfigurationMessage() {
        var state = SetupFlowState(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")])
            ],
            configurationMessage: "Could not save settings. Try again."
        )

        state.selectAppPage(.kubernetes)

        #expect(state.selectedSettingsTab == .kubernetes)
        #expect(state.configurationMessage == nil)
    }

    @Test("selecting a context page loads that context watchlist")
    func selectingAContextPageLoadsThatContextWatchlist() {
        var state = SetupFlowState(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")]),
                "stage": WatchlistSelectionState(selectedTargets: [.namespace("web")])
            ]
        )

        state.selectContext("stage")

        #expect(state.selectedSettingsTab == .context("stage"))
        #expect(state.watchlist.isSelected(.namespace("web")))
    }

    @Test("completed config is unchanged by app page navigation")
    func completedConfigIsUnchangedByAppPageNavigation() {
        var state = SetupFlowState(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")]),
                "stage": WatchlistSelectionState(selectedTargets: [.namespace("web")])
            ]
        )

        state.selectContext("stage")
        state.selectAppPage(.general)

        #expect(state.selectedContext == "stage")
        #expect(state.selectedContextForCompletedConfig == "prod")
        #expect(state.isConfigured)
    }

    @Test("select app page ignores context pages")
    func selectAppPageIgnoresContextPages() {
        var state = SetupFlowState(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")])
            ]
        )

        state.selectAppPage(.general)
        state.selectAppPage(.context("prod"))

        #expect(state.selectedSettingsTab == .general)
    }

    @Test("missing context or watchlist keeps setup active")
    func missingContextOrWatchlistKeepsSetupActive() {
        let state = SetupFlowState(
            selectedContext: nil,
            availableContexts: ["prod"],
            watchlist: WatchlistSelectionState(
                availableNamespaces: ["api"],
                availableWorkloads: [.workload(namespace: "api", name: "checkout", kind: .deployment)]
            )
        )

        #expect(state.needsSetup)
        #expect(state.title == "Set up Kubebar")
        #expect(state.watchlist.emptyStateTitle == "No namespaces selected")
        #expect(state.watchlistHelpText == "Choose namespaces to keep Kubebar focused on the first screen.")
    }

    @Test("configured context and watchlist can complete setup")
    func configuredContextAndWatchlistCanCompleteSetup() {
        let state = SetupFlowState(
            selectedContext: "prod",
            availableContexts: ["prod", "staging"],
            watchlist: WatchlistSelectionState(
                availableNamespaces: ["api", "monitoring"],
                selectedTargets: [.namespace("monitoring")]
            )
        )

        #expect(state.isConfigured)
        #expect(state.title == "Kubebar is ready")
        #expect(state.contextHelpText == "Saved context: prod")
        #expect(state.watchlistHelpText == "1 namespace selected")
    }

    @Test("context tabs include only local available contexts")
    func contextTabsIncludeOnlyLocalAvailableContexts() {
        let state = SetupFlowState(
            selectedContext: "default",
            availableContexts: ["prod", "stage"],
            watchlistsByContext: [
                "default": WatchlistSelectionState(selectedTargets: [.namespace("api")])
            ]
        )

        #expect(state.contextTabs == ["prod", "stage"])
        #expect(state.watchlist.isSelected(.namespace("api")))
    }

    @Test("settings tabs start with app pages and then contexts")
    func settingsTabsStartWithAppPagesAndThenContexts() {
        let state = SetupFlowState(
            selectedContext: "prod",
            availableContexts: ["prod", "stage"],
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")])
            ]
        )

        #expect(state.settingsTabs == [.general, .kubernetes, .notifications, .aiAssistant, .context("prod"), .context("stage")])
        #expect(state.settingsTabs.first == .general)
    }

    @Test("settings tab ids stay stable with two contexts")
    func settingsTabIDsStayStableWithTwoContexts() {
        let state = SetupFlowState(
            selectedContext: "prod",
            availableContexts: ["prod", "stage"],
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")])
            ]
        )

        #expect(state.selectedSettingsTabID == .general)
        #expect(state.settingsTabs.map(\.id) == [.general, .kubernetes, .notifications, .aiAssistant, .context("prod"), .context("stage")])
        #expect(state.settingsTab(for: .general) == .general)
        #expect(state.settingsTab(for: .context("stage")) == .context("stage"))
    }

    @Test("selecting app settings preserves current context watchlist edits")
    func selectingAppSettingsPreservesCurrentContextWatchlistEdits() {
        var state = SetupFlowState(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")]),
                "stage": WatchlistSelectionState(selectedTargets: [.namespace("web")])
            ]
        )

        state.selectContext("stage")
        state.watchlist.toggle(.namespace("ops"))
        state.selectAppSettingsTab()

        #expect(state.selectedSettingsTab == .appSettings)
        #expect(state.selectedSettingsTabID == .appSettings)
        #expect(state.currentWatchlistsByContext()["stage"]?.isSelected(.namespace("web")) == true)
        #expect(state.currentWatchlistsByContext()["stage"]?.isSelected(.namespace("ops")) == true)
    }

    @Test("app settings completion context keeps original selected context")
    func appSettingsCompletionContextKeepsOriginalSelectedContext() {
        var state = SetupFlowState(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")]),
                "stage": WatchlistSelectionState(selectedTargets: [.namespace("web")])
            ]
        )

        state.selectContext("stage")
        state.selectAppSettingsTab()

        #expect(state.selectedContext == "stage")
        #expect(state.selectedContextForCompletedConfig == "prod")
        #expect(state.isConfigured)
    }

    @Test("configured setup can use settings save primary action")
    func configuredSetupCanUseSettingsSavePrimaryAction() {
        let state = SetupFlowState(
            selectedContext: "prod",
            watchlist: WatchlistSelectionState(
                selectedTargets: [.namespace("api")]
            )
        )

        #expect(state.primaryActionTitle(isEditingExistingConfig: true) == "Save Settings")
    }

    @Test("first use setup keeps finish setup primary action")
    func firstUseSetupKeepsFinishSetupPrimaryAction() {
        let state = SetupFlowState(
            selectedContext: nil,
            watchlist: WatchlistSelectionState()
        )

        #expect(state.primaryActionTitle(isEditingExistingConfig: true) == "Finish setup")
    }

    @Test("settings save failure copy is concise")
    func settingsSaveFailureCopyIsConcise() {
        #expect(SetupFlowState.settingsSaveFailureMessage == "Could not save settings. Try again.")
    }

    @Test("failed target loading preserves configured setup")
    func failedTargetLoadingPreservesConfiguredSetup() {
        let state = SetupFlowState(
            selectedContext: "prod",
            watchlist: WatchlistSelectionState(
                selectedTargets: [.namespace("api")]
            ),
            targetLoadingState: .failed("forbidden")
        )

        #expect(state.isConfigured)
        #expect(state.watchlistHelpText == "1 namespace selected")
    }

    @Test("available targets alone do not complete setup")
    func availableTargetsAloneDoNotCompleteSetup() {
        let state = SetupFlowState(
            selectedContext: "prod",
            watchlist: WatchlistSelectionState(
                availableNamespaces: ["api"],
                availableWorkloads: [.workload(namespace: "api", name: "checkout", kind: .deployment)]
            )
        )

        #expect(!state.isConfigured)
        #expect(state.watchlistHelpText == "Choose namespaces to keep Kubebar focused on the first screen.")
    }

    @Test("start at login defaults off without a message")
    func startAtLoginDefaultsOffWithoutMessage() {
        let state = SetupFlowState()

        #expect(!state.startAtLogin.isEnabled)
        #expect(state.startAtLogin.message == nil)
    }

    @Test("health shift alerts default off without a message")
    func healthShiftAlertsDefaultOffWithoutMessage() {
        let state = SetupFlowState()

        #expect(!state.healthShiftAlerts.isEnabled)
        #expect(state.healthShiftAlerts.message == nil)
    }

    @Test("kubeconfig paths default empty")
    func kubeconfigPathsDefaultEmpty() {
        let state = SetupFlowState()

        #expect(state.kubeconfigPaths.isEmpty)
    }

    @Test("kubeconfig paths persist while switching contexts and app settings")
    func kubeconfigPathsPersistWhileSwitchingContextsAndAppSettings() {
        var state = SetupFlowState(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")]),
                "stage": WatchlistSelectionState(selectedTargets: [.namespace("web")])
            ],
            kubeconfigPaths: [
                "/Users/derek/.kube/config",
                "/Users/derek/.kube/prod.yaml"
            ]
        )

        state.selectContext("stage")
        state.selectAppSettingsTab()

        #expect(state.kubeconfigPaths == [
            "/Users/derek/.kube/config",
            "/Users/derek/.kube/prod.yaml"
        ])
    }

    @Test("appending kubeconfig paths trims empties and skips duplicates")
    func appendingKubeconfigPathsTrimsEmptiesAndSkipsDuplicates() {
        var state = SetupFlowState(
            kubeconfigPaths: ["/Users/derek/.kube/config"]
        )

        state.appendKubeconfigPaths([
            "  ",
            "/Users/derek/.kube/config",
            "/Users/derek/.kube/team.yaml",
            "/Users/derek/.kube/team.yaml"
        ])

        #expect(state.kubeconfigPaths == [
            "/Users/derek/.kube/config",
            "/Users/derek/.kube/team.yaml"
        ])
    }

    @Test("kubeconfig path rows can be removed and reordered")
    func kubeconfigPathRowsCanBeRemovedAndReordered() {
        var state = SetupFlowState(
            kubeconfigPaths: [
                "/Users/derek/.kube/config",
                "/Users/derek/.kube/team.yaml",
                "/Users/derek/.kube/prod.yaml"
            ]
        )

        state.moveKubeconfigPathUp(at: 2)
        #expect(state.kubeconfigPaths == [
            "/Users/derek/.kube/config",
            "/Users/derek/.kube/prod.yaml",
            "/Users/derek/.kube/team.yaml"
        ])

        state.moveKubeconfigPathDown(at: 0)
        #expect(state.kubeconfigPaths == [
            "/Users/derek/.kube/prod.yaml",
            "/Users/derek/.kube/config",
            "/Users/derek/.kube/team.yaml"
        ])

        state.removeKubeconfigPath(at: 1)
        #expect(state.kubeconfigPaths == [
            "/Users/derek/.kube/prod.yaml",
            "/Users/derek/.kube/team.yaml"
        ])
    }

    @Test("replacing available contexts hides missing tabs but preserves saved watchlists")
    func replacingAvailableContextsHidesMissingTabsButPreservesSavedWatchlists() {
        var state = SetupFlowState(
            selectedContext: "prod",
            availableContexts: ["prod", "stage"],
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")]),
                "stage": WatchlistSelectionState(selectedTargets: [.namespace("web")])
            ]
        )

        state.selectContext("stage")
        state.replaceAvailableContexts(["prod"])

        #expect(state.contextTabs == ["prod"])
        #expect(state.selectedSettingsTab == .appSettings)
        #expect(state.currentWatchlistsByContext()["stage"]?.isSelected(.namespace("web")) == true)
    }

    @Test("ai diagnostic assistant config defaults unconfigured")
    func aiDiagnosticAssistantConfigDefaultsUnconfigured() {
        let state = SetupFlowState()

        #expect(state.aiDiagnosticAssistant.config == AIDiagnosticAssistantConfig())
        #expect(state.aiDiagnosticAssistant.config.modelID.isEmpty)
    }

    @Test("ai diagnostic assistant config persists while switching tabs")
    func aiDiagnosticAssistantConfigPersistsWhileSwitchingTabs() {
        var state = SetupFlowState(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": WatchlistSelectionState(selectedTargets: [.namespace("api")]),
                "stage": WatchlistSelectionState(selectedTargets: [.namespace("web")])
            ],
            aiDiagnosticAssistant: AIDiagnosticAssistantState(
                config: AIDiagnosticAssistantConfig(
                    provider: .gemini,
                    modelID: "gemini-1.5-flash",
                    baseURL: nil
                )
            )
        )

        state.selectContext("stage")
        state.selectAppSettingsTab()

        #expect(state.aiDiagnosticAssistant.config.provider == .gemini)
        #expect(state.aiDiagnosticAssistant.config.modelID == "gemini-1.5-flash")
    }

    @Test("updating ai diagnostic assistant config clears configuration message")
    func updatingAIDiagnosticAssistantConfigClearsConfigurationMessage() {
        var state = SetupFlowState(
            configurationMessage: "Could not save settings. Try again."
        )

        state.updateAIDiagnosticAssistant(modelID: "gpt-4o-mini")

        #expect(state.aiDiagnosticAssistant.config.modelID == "gpt-4o-mini")
        #expect(state.configurationMessage == nil)
    }

    @Test("updating ai prompt instructions stores custom overrides")
    func updatingAIPromptInstructionsStoresCustomOverrides() {
        var state = SetupFlowState(
            configurationMessage: "Could not save settings. Try again."
        )

        state.updateAIPodDiagnosticPromptInstructions("Custom Pod instructions")
        state.updateAIEventDiagnosticPromptInstructions("Custom Event instructions")

        #expect(state.aiDiagnosticAssistant.config.podPromptInstructions == "Custom Pod instructions")
        #expect(state.aiDiagnosticAssistant.config.eventPromptInstructions == "Custom Event instructions")
        #expect(state.configurationMessage == nil)
    }

    @Test("blank ai prompt instructions fall back to default")
    func blankAIPromptInstructionsFallBackToDefault() {
        var state = SetupFlowState()

        state.updateAIPodDiagnosticPromptInstructions("   \n  ")
        state.updateAIEventDiagnosticPromptInstructions("")

        #expect(state.aiDiagnosticAssistant.config.podPromptInstructions == nil)
        #expect(state.aiDiagnosticAssistant.config.eventPromptInstructions == nil)
        #expect(state.aiDiagnosticAssistant.config.effectivePodPromptInstructions == AIDiagnosticAssistantConfig.defaultPodPromptInstructions)
        #expect(state.aiDiagnosticAssistant.config.effectiveEventPromptInstructions == AIDiagnosticAssistantConfig.defaultEventPromptInstructions)
    }

    @Test("resetting ai prompts clears overrides")
    func resettingAIPromptsClearsOverrides() {
        var state = SetupFlowState(
            aiDiagnosticAssistant: AIDiagnosticAssistantState(
                config: AIDiagnosticAssistantConfig(
                    provider: .openAI,
                    modelID: "gpt-4o-mini",
                    podPromptInstructions: "Custom Pod instructions",
                    eventPromptInstructions: "Custom Event instructions"
                )
            )
        )

        state.resetAIPodDiagnosticPromptInstructions()
        state.resetAIEventDiagnosticPromptInstructions()

        #expect(state.aiDiagnosticAssistant.config.podPromptInstructions == nil)
        #expect(state.aiDiagnosticAssistant.config.eventPromptInstructions == nil)
        #expect(state.aiDiagnosticAssistant.config.effectivePodPromptInstructions == AIDiagnosticAssistantConfig.defaultPodPromptInstructions)
        #expect(state.aiDiagnosticAssistant.config.effectiveEventPromptInstructions == AIDiagnosticAssistantConfig.defaultEventPromptInstructions)
    }

    @Test("updating ai provider preserves prompt overrides")
    func updatingAIProviderPreservesPromptOverrides() {
        var state = SetupFlowState(
            aiDiagnosticAssistant: AIDiagnosticAssistantState(
                config: AIDiagnosticAssistantConfig(
                    provider: .openAI,
                    modelID: "gpt-4o-mini",
                    podPromptInstructions: "Custom Pod instructions",
                    eventPromptInstructions: "Custom Event instructions"
                ),
                testConnectionResult: .success
            )
        )

        state.updateAIDiagnosticAssistant(provider: .anthropic)

        #expect(state.aiDiagnosticAssistant.config.provider == .anthropic)
        #expect(state.aiDiagnosticAssistant.config.podPromptInstructions == "Custom Pod instructions")
        #expect(state.aiDiagnosticAssistant.config.eventPromptInstructions == "Custom Event instructions")
        #expect(state.aiDiagnosticAssistant.testConnectionResult == nil)
    }

    @Test("updating ai provider clears test connection result")
    func updatingAIProviderClearsTestConnectionResult() {
        var state = SetupFlowState(
            aiDiagnosticAssistant: AIDiagnosticAssistantState(
                config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
                testConnectionResult: .success
            )
        )

        state.updateAIDiagnosticAssistant(provider: .anthropic)

        #expect(state.aiDiagnosticAssistant.config.provider == .anthropic)
        #expect(state.aiDiagnosticAssistant.testConnectionResult == nil)
    }

    @Test("api key draft is transient and resets when settings reopen")
    func apiKeyDraftIsTransientAndResetsWhenSettingsReopen() {
        let savedConfig = AppConfig(
            selectedContext: "prod",
            watchTargets: [.namespace("api")],
            aiDiagnosticAssistant: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini")
        )
        var state = MenuRuntimeState(config: savedConfig)
        state.setupState.aiDiagnosticAssistant.apiKeyDraft = "sk-test-secret"
        state.prepareSettings(config: savedConfig)

        #expect(state.setupState.aiDiagnosticAssistant.apiKeyDraft.isEmpty)
        #expect(state.setupState.aiDiagnosticAssistant.config.modelID == "gpt-4o-mini")
    }
}
