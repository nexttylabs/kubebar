import Testing
@testable import KubebarCore

@Suite("Watchlist selection state")
struct WatchlistSelectionStateTests {
    @Test("empty state explains what to add")
    func emptyStateExplainsWhatToAdd() {
        let state = WatchlistSelectionState()

        #expect(state.isEmpty)
        #expect(state.emptyStateTitle == "No watch targets available")
        #expect(state.emptyStateMessage == "Add a namespace or workload source to start building the watchlist.")
    }

    @Test("toggle helpers select and clear targets")
    func toggleHelpersSelectAndClearTargets() {
        var state = WatchlistSelectionState(
            availableNamespaces: ["api", "monitoring"],
            availableWorkloads: [.workload(namespace: "api", name: "checkout")]
        )

        state.toggleNamespace("api")
        state.toggleWorkload(namespace: "api", name: "checkout")

        #expect(state.isSelected(.namespace("api")))
        #expect(state.isSelected(.workload(namespace: "api", name: "checkout")))
        #expect(state.selectedCount == 2)

        state.toggle(.namespace("api"))

        #expect(!state.isSelected(.namespace("api")))
        #expect(state.selectedCount == 1)
        #expect(state.selectionSummary == "1 target selected")
    }
}
