import Testing
@testable import KubebarCore

@Suite("App config")
struct AppConfigTests {
    @Test("selecting context preserves watchlists and global settings")
    func selectingContextPreservesWatchlistsAndGlobalSettings() {
        let config = AppConfig(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": [.namespace("api")],
                "stage": [.namespace("web")]
            ],
            refreshIntervalSeconds: 120,
            healthShiftAlertsEnabled: true,
            kubeconfigPaths: [
                "/Users/derek/.kube/config",
                "/Users/derek/.kube/prod.yaml"
            ]
        )

        let updated = config.selectingContext("stage")

        #expect(updated.selectedContext == "stage")
        #expect(updated.watchlistsByContext == config.watchlistsByContext)
        #expect(updated.refreshIntervalSeconds == 120)
        #expect(updated.healthShiftAlertsEnabled)
        #expect(updated.kubeconfigPaths == [
            "/Users/derek/.kube/config",
            "/Users/derek/.kube/prod.yaml"
        ])
        #expect(updated.watchTargets == [.namespace("web")])
        #expect(!updated.needsSetup)
    }

    @Test("kubeconfig paths default empty")
    func kubeconfigPathsDefaultEmpty() {
        let config = AppConfig()

        #expect(config.kubeconfigPaths.isEmpty)
    }

    @Test("selecting context without watchlist marks config incomplete")
    func selectingContextWithoutWatchlistMarksConfigIncomplete() {
        let config = AppConfig(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": [.namespace("api")]
            ]
        )

        let updated = config.selectingContext("stage")

        #expect(updated.selectedContext == "stage")
        #expect(updated.watchTargets.isEmpty)
        #expect(updated.needsSetup)
    }
}
