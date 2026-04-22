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
        let metricsUnavailable = MenuStateFixtureCatalog.fixture(for: .metricsUnavailable)
        let warningHeavy = MenuStateFixtureCatalog.fixture(for: .warningHeavy)

        #expect(healthy.display.state == .ok)
        #expect(healthy.display.podTab.summary == "3/3 watched pods ready")
        #expect(healthy.display.podTab.sections.map(\.namespace) == ["qa-api", "qa-monitoring"])
        #expect(watch.display.state == .watch)
        #expect(watch.display.podTab.sections.first?.namespace == "qa-api")
        #expect(watch.display.podTab.sections.first?.rows.first?.state == .watch)
        #expect(watch.display.podTab.sections.first?.rows.first?.readyLabel == "0/1")
        #expect(watch.display.podTab.sections.first?.rows.first?.issueText == "ContainersNotReady: containers with unready status")
        #expect(bad.display.state == .bad)
        #expect(bad.display.podTab.sections.first?.namespace == "qa-payments")
        #expect(bad.display.podTab.sections.first?.rows.first?.state == .bad)
        #expect(bad.display.podTab.sections.first?.rows.first?.name == "qa-payments-api-0")
        #expect(bad.display.podTab.sections.first?.rows.first?.readyLabel == "0/1")
        #expect(bad.display.podTab.sections.first?.rows.first?.issueText == "Error: container exited with code 1")
        #expect(staleRefreshFailure.display.state == .stale)
        #expect(staleAgeOut.display.state == .stale)
        #expect(kubectlFailure.display.state == .stale)
        #expect(metricsUnavailable.display.state == .ok)
        #expect(metricsUnavailable.display.podTab.sections.isEmpty == false)
        #expect(metricsUnavailable.display.overview.cards.first(where: { $0.id == "cpu" })?.state == .unavailable)
        #expect(metricsUnavailable.display.nodeTab.rows.count == 3)
        #expect(metricsUnavailable.display.nodeTab.rows.allSatisfy { $0.cpuLabel == "-" && $0.memoryLabel == "-" })
        #expect(bad.display.nodeTab.rows.first?.name == "qa-worker-2")
        #expect(bad.display.nodeTab.rows.first?.readiness == .notReady)
        #expect(bad.display.nodeTab.rows.first?.issueText == "KubeletNotReady: container runtime is down")
        #expect(warningHeavy.display.state == .watch)
        #expect(warningHeavy.display.overview.recentWarnings.count == 2)
        #expect(warningHeavy.display.overview.recentWarnings.first?.reason == "BackOff")
        #expect(warningHeavy.display.overview.recentWarnings.first?.isTracked == true)
        #expect(warningHeavy.display.overview.recentWarnings.first?.metadataLabel == "1m ago / x2")
        #expect(warningHeavy.display.overview.recentWarnings.first?.secondaryText == "qa-api/pod/qa-checkout-7f9 - Container is backing off after repeated restarts.")
        #expect(warningHeavy.display.overview.recentWarningsOverflowCount == 1)
    }

    @Test("watch fixture exposes reason first warning details")
    func watchFixtureExposesReasonFirstWarningDetails() {
        let fixture = MenuStateFixtureCatalog.fixture(for: .watch)
        let warning = fixture.display.overview.recentWarnings.first

        #expect(warning?.reason == "BackOff")
        #expect(warning?.location == "qa-api/pod/qa-checkout-7f9")
        #expect(warning?.metadataLabel == "30s ago / x2")
        #expect(warning?.isTracked == true)
        #expect(warning?.secondaryText == "qa-api/pod/qa-checkout-7f9 - Container is backing off after repeated restarts.")
        #expect(warning?.accessibilityLabel.contains("Tracked object warning, BackOff") == true)
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

    @Test("overview fixture copy no longer describes Watching rows")
    func overviewFixtureCopyNoLongerDescribesWatchingRows() {
        let metadata = MenuQAState.allCases
            .map { MenuStateFixtureCatalog.fixture(for: $0).expectedBehavior }
            .joined(separator: "\n")

        #expect(!metadata.contains("Watching rows"))
        #expect(!metadata.contains("Watching section"))
    }
}
