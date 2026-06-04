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
            healthShiftAlertsEnabled: true
        )

        let updated = config.selectingContext("stage")

        #expect(updated.selectedContext == "stage")
        #expect(updated.watchlistsByContext == config.watchlistsByContext)
        #expect(updated.refreshIntervalSeconds == 120)
        #expect(updated.healthShiftAlertsEnabled)
        #expect(updated.watchTargets == [.namespace("web")])
        #expect(!updated.needsSetup)
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
