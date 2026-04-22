import Testing
@testable import KubebarCore

@Suite("Watchlist selection state")
struct WatchlistSelectionStateTests {
    @Test("empty state explains what to add")
    func emptyStateExplainsWhatToAdd() {
        let state = WatchlistSelectionState()

        #expect(state.isEmpty)
        #expect(state.emptyStateTitle == "No namespaces available")
        #expect(state.emptyStateMessage == "Choose a cluster context or retry loading namespaces.")
    }

    @Test("toggle helpers select and clear targets")
    func toggleHelpersSelectAndClearTargets() {
        var state = WatchlistSelectionState(
            availableNamespaces: ["api", "monitoring"],
            availableWorkloads: [.workload(namespace: "api", name: "checkout", kind: .deployment)]
        )

        state.toggleNamespace("api")
        state.toggleWorkload(namespace: "api", name: "checkout")

        #expect(state.isSelected(.namespace("api")))
        #expect(state.isSelected(.workload(namespace: "api", name: "checkout", kind: .deployment)))
        #expect(state.selectedCount == 2)

        state.toggle(.namespace("api"))

        #expect(!state.isSelected(.namespace("api")))
        #expect(state.selectedCount == 1)
        #expect(state.selectionSummary == "1 target selected")
        #expect(state.namespaceSelectionSummary == "0 namespaces selected")
    }

    @Test("candidate replacement preserves selected targets")
    func candidateReplacementPreservesSelectedTargets() {
        var state = WatchlistSelectionState(
            selectedTargets: [.workload(namespace: "api", name: "checkout", kind: .deployment)]
        )

        state.replaceAvailableTargets(
            WatchlistCandidates(
                namespaces: ["api"],
                workloads: [.workload(namespace: "api", name: "checkout", kind: .deployment)]
            )
        )

        #expect(state.availableNamespaces == ["api"])
        #expect(state.availableWorkloads.isEmpty)
        #expect(state.isSelected(.workload(namespace: "api", name: "checkout", kind: .deployment)))

        state.clearAvailableTargets()

        #expect(state.availableNamespaces.isEmpty)
        #expect(state.availableWorkloads.isEmpty)
        #expect(state.isSelected(.workload(namespace: "api", name: "checkout", kind: .deployment)))
    }
}
