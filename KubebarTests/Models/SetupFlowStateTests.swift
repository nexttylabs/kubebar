import Testing
@testable import KubebarCore

@Suite("Setup flow state")
struct SetupFlowStateTests {
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
        #expect(state.watchlist.emptyStateTitle == "No watch targets selected")
        #expect(state.watchlistHelpText == "Choose namespaces or workloads to keep Kubebar focused on the first screen.")
    }

    @Test("configured context and watchlist can complete setup")
    func configuredContextAndWatchlistCanCompleteSetup() {
        let state = SetupFlowState(
            selectedContext: "prod",
            availableContexts: ["prod", "staging"],
            watchlist: WatchlistSelectionState(
                availableNamespaces: ["api", "monitoring"],
                availableWorkloads: [.workload(namespace: "api", name: "checkout", kind: .deployment)],
                selectedTargets: [
                    .namespace("monitoring"),
                    .workload(namespace: "api", name: "checkout", kind: .deployment)
                ]
            )
        )

        #expect(state.isConfigured)
        #expect(state.title == "Kubebar is ready")
        #expect(state.contextHelpText == "Saved context: prod")
        #expect(state.watchlistHelpText == "2 targets selected")
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
                selectedTargets: [.workload(namespace: "api", name: "checkout", kind: .deployment)]
            ),
            targetLoadingState: .failed("forbidden")
        )

        #expect(state.isConfigured)
        #expect(state.watchlistHelpText == "1 target selected")
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
        #expect(state.watchlistHelpText == "Choose namespaces or workloads to keep Kubebar focused on the first screen.")
    }
}
