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
                availableWorkloads: [.workload(namespace: "api", name: "checkout")]
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
                availableWorkloads: [.workload(namespace: "api", name: "checkout")],
                selectedTargets: [
                    .namespace("monitoring"),
                    .workload(namespace: "api", name: "checkout")
                ]
            )
        )

        #expect(state.isConfigured)
        #expect(state.title == "Kubebar is ready")
        #expect(state.contextHelpText == "Saved context: prod")
        #expect(state.watchlistHelpText == "2 targets selected")
    }
}
