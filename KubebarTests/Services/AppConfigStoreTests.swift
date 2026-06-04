import Foundation
import Testing
@testable import KubebarCore

@Suite("App config store")
struct AppConfigStoreTests {
    @Test("missing config loads an empty setup state")
    func missingConfigLoadsEmptySetupState() throws {
        let store = AppConfigStore(directory: makeTemporaryDirectory())

        let config = try store.load()

        #expect(config.selectedContext == nil)
        #expect(config.watchTargets.isEmpty)
        #expect(config.watchlistsByContext.isEmpty)
        #expect(config.needsSetup)
        #expect(config.refreshIntervalSeconds == 60)
        #expect(config.refreshCadence == .oneMinute)
        #expect(!config.healthShiftAlertsEnabled)
        #expect(config.kubeconfigPaths.isEmpty)
    }

    @Test("unknown refresh interval normalizes to default")
    func unknownRefreshIntervalNormalizesToDefault() {
        let config = AppConfig(
            selectedContext: "prod",
            watchTargets: [.namespace("api")],
            refreshIntervalSeconds: 999
        )

        #expect(config.refreshIntervalSeconds == 60)
        #expect(config.refreshCadence == .oneMinute)
        #expect(!config.healthShiftAlertsEnabled)
    }

    @Test("saved config without health shift alert setting defaults off")
    func savedConfigWithoutHealthShiftAlertSettingDefaultsOff() throws {
        let directory = makeTemporaryDirectory()
        let configURL = directory.appendingPathComponent("config.json")
        let json = """
        {
          "selectedContext": "prod",
          "refreshIntervalSeconds": 60,
          "watchTargets": [
            {"namespace": {"_0": "api"}}
          ]
        }
        """
        try json.write(to: configURL, atomically: true, encoding: .utf8)
        let store = AppConfigStore(directory: directory)

        let config = try store.load()

        #expect(config.watchlistsByContext["prod"] == [.namespace("api")])
        #expect(config.watchTargets == [.namespace("api")])
        #expect(!config.healthShiftAlertsEnabled)
        #expect(config.kubeconfigPaths.isEmpty)
    }

    @Test("unknown saved refresh interval loads as default")
    func unknownSavedRefreshIntervalLoadsAsDefault() throws {
        let directory = makeTemporaryDirectory()
        let configURL = directory.appendingPathComponent("config.json")
        let json = """
        {
          "selectedContext": "prod",
          "refreshIntervalSeconds": 999,
          "watchTargets": [
            {"namespace": {"_0": "api"}}
          ]
        }
        """
        try json.write(to: configURL, atomically: true, encoding: .utf8)
        let store = AppConfigStore(directory: directory)

        let config = try store.load()

        #expect(config.refreshIntervalSeconds == 60)
        #expect(config.refreshCadence == .oneMinute)
        #expect(config.kubeconfigPaths.isEmpty)
    }

    @Test("saved context and watchlist round trip")
    func savedContextAndWatchlistRoundTrip() throws {
        let store = AppConfigStore(directory: makeTemporaryDirectory())
        let config = AppConfig(
            selectedContext: "prod",
            watchTargets: [
                .workload(namespace: "api", name: "checkout", kind: .deployment),
                .namespace("monitoring")
            ],
            refreshIntervalSeconds: 60,
            healthShiftAlertsEnabled: true,
            kubeconfigPaths: [
                "/Users/derek/.kube/config",
                "/Users/derek/.kube/team.yaml"
            ]
        )

        try store.save(config)

        #expect(try store.load() == config)
        #expect(try store.load().watchlistsByContext["prod"] == [
            .workload(namespace: "api", name: "checkout", kind: .deployment),
            .namespace("monitoring")
        ])
        #expect(try store.load().kubeconfigPaths == [
            "/Users/derek/.kube/config",
            "/Users/derek/.kube/team.yaml"
        ])
    }

    @Test("per-context watchlists round trip")
    func perContextWatchlistsRoundTrip() throws {
        let directory = makeTemporaryDirectory()
        let store = AppConfigStore(directory: directory)
        let config = AppConfig(
            selectedContext: "stage",
            watchlistsByContext: [
                "prod": [.namespace("api")],
                "stage": [.namespace("web"), .namespace("ops")]
            ],
            refreshIntervalSeconds: 120,
            healthShiftAlertsEnabled: true,
            kubeconfigPaths: [
                "/Users/derek/.kube/config",
                "/Users/derek/.kube/stage.yaml"
            ]
        )

        try store.save(config)
        let loaded = try store.load()

        #expect(loaded == config)
        #expect(loaded.watchTargets == [.namespace("web"), .namespace("ops")])
        #expect(loaded.watchlistsByContext["prod"] == [.namespace("api")])
        #expect(loaded.watchlistsByContext["stage"] == [.namespace("web"), .namespace("ops")])
        #expect(loaded.refreshIntervalSeconds == 120)
        #expect(loaded.healthShiftAlertsEnabled)
        #expect(loaded.kubeconfigPaths == [
            "/Users/derek/.kube/config",
            "/Users/derek/.kube/stage.yaml"
        ])

        let savedData = try Data(contentsOf: directory.appendingPathComponent("config.json"))
        let savedPayload = try JSONDecoder().decode(SavedConfigPayload.self, from: savedData)
        #expect(savedPayload.watchTargets == [.namespace("web"), .namespace("ops")])
    }

    @Test("selected context without watchlist needs setup")
    func selectedContextWithoutWatchlistNeedsSetup() {
        let config = AppConfig(
            selectedContext: "stage",
            watchlistsByContext: [
                "prod": [.namespace("api")]
            ]
        )

        #expect(config.watchTargets.isEmpty)
        #expect(config.needsSetup)
    }

    @Test("corrupt config reports a recoverable error")
    func corruptConfigReportsRecoverableError() throws {
        let directory = makeTemporaryDirectory()
        let configURL = directory.appendingPathComponent("config.json")
        try "{not-json".write(to: configURL, atomically: true, encoding: .utf8)
        let store = AppConfigStore(directory: directory)

        #expect(throws: AppConfigStoreError.corruptConfig) {
            try store.load()
        }
    }

    @Test("old workload config decodes with deployment kind")
    func oldWorkloadConfigDecodesWithDeploymentKind() throws {
        let directory = makeTemporaryDirectory()
        let configURL = directory.appendingPathComponent("config.json")
        let json = """
        {
          "selectedContext": "prod",
          "refreshIntervalSeconds": 60,
          "watchTargets": [
            {"workload": {"namespace": "api", "name": "checkout"}}
          ]
        }
        """
        try json.write(to: configURL, atomically: true, encoding: .utf8)
        let store = AppConfigStore(directory: directory)

        let config = try store.load()

        #expect(config.watchTargets == [.workload(namespace: "api", name: "checkout", kind: .deployment)])
        #expect(config.refreshIntervalSeconds == 60)
        #expect(config.kubeconfigPaths.isEmpty)
    }

    @Test("save failure reports cannot save")
    func saveFailureReportsCannotSave() throws {
        let directory = makeTemporaryDirectory()
        let blockedDirectory = directory.appendingPathComponent("not-a-directory")
        try "file".write(to: blockedDirectory, atomically: true, encoding: .utf8)
        let store = AppConfigStore(directory: blockedDirectory)

        #expect(throws: AppConfigStoreError.cannotSave) {
            try store.save(AppConfig(selectedContext: "prod", watchTargets: [.namespace("api")]))
        }
    }

    private func makeTemporaryDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("kubebar-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private struct SavedConfigPayload: Decodable {
        let watchTargets: [WatchTarget]
    }
}
