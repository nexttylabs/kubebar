import Foundation
import Testing
@testable import KubebarCore

@Suite("Menu QA fixtures")
struct MenuStateFixtureCatalogTests {
    @Test("required fixture metadata is complete", arguments: MenuQAState.allCases)
    func requiredFixtureMetadataIsComplete(_ state: MenuQAState) {
        let fixture = MenuStateFixtureCatalog.fixture(for: state)

        #expect(fixture.id == state)
        #expect(!fixture.reproductionSteps.isEmpty)
        #expect(!fixture.expectedBehavior.isEmpty)
        #expect(!fixture.evidencePath.isEmpty)
        #expect(!fixture.limitations.isEmpty)
        #expect(!fixture.followUpRisk.isEmpty)
    }

    @Test("required fixtures map to locked display states")
    func requiredFixturesMapToLockedDisplayStates() {
        let healthy = MenuStateFixtureCatalog.fixture(for: .healthy)
        let watch = MenuStateFixtureCatalog.fixture(for: .watch)
        let bad = MenuStateFixtureCatalog.fixture(for: .bad)
        let staleRefreshFailure = MenuStateFixtureCatalog.fixture(for: .staleRefreshFailure)
        let staleAgeOut = MenuStateFixtureCatalog.fixture(for: .staleAgeOut)
        let kubectlFailure = MenuStateFixtureCatalog.fixture(for: .kubectlFailure)

        #expect(healthy.display.state == .ok)
        #expect(watch.display.state == .watch)
        #expect(bad.display.state == .bad)
        #expect(staleRefreshFailure.display.state == .stale)
        #expect(staleAgeOut.display.state == .stale)
        #expect(kubectlFailure.display.state == .stale)
    }

    @Test("first use and empty watchlist remain distinct setup states")
    func firstUseAndEmptyWatchlistRemainDistinctSetupStates() {
        let firstUse = MenuStateFixtureCatalog.fixture(for: .firstUse)
        let emptyWatchlist = MenuStateFixtureCatalog.fixture(for: .emptyWatchlist)

        #expect(firstUse.isShowingSetup == true)
        #expect(firstUse.setupState.selectedContext == nil)
        #expect(emptyWatchlist.isShowingSetup == true)
        #expect(emptyWatchlist.setupState.selectedContext == "QA fixture")
        #expect(emptyWatchlist.setupState.watchlist.isEmpty == true)
        #expect(firstUse.setupState != emptyWatchlist.setupState)
    }

    @Test("fixture lookup uses raw value names")
    func fixtureLookupUsesRawValueNames() throws {
        let fixture = try #require(MenuStateFixtureCatalog.fixture(named: "stale-refresh-failure"))

        #expect(fixture.id == .staleRefreshFailure)
        #expect(MenuStateFixtureCatalog.fixture(named: "missing") == nil)
    }

    @Test("metadata and failure displays do not expose sensitive strings")
    func metadataAndFailureDisplaysDoNotExposeSensitiveStrings() {
        let deniedStrings = [
            "/Users/",
            ".kube/config",
            "client-key-data",
            "client-certificate-data",
            "Bearer ",
            "{\"apiVersion\"",
            "{\"items\"",
            "token expired"
        ]
        let metadata = MenuQAState.allCases
            .map { MenuStateFixtureCatalog.fixture(for: $0) }
            .map { fixture in
                [
                    fixture.reproductionSteps,
                    fixture.expectedBehavior,
                    fixture.evidencePath,
                    fixture.limitations,
                    fixture.followUpRisk,
                    fixture.display.healthSentence,
                    fixture.display.primaryStatusReason,
                    fixture.display.staleBanner?.reason ?? ""
                ].joined(separator: "\n")
            }
            .joined(separator: "\n")

        for deniedString in deniedStrings {
            #expect(!metadata.contains(deniedString))
        }
    }
}
