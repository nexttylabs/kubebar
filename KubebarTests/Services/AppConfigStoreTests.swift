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
        #expect(config.needsSetup)
        #expect(config.refreshIntervalSeconds == 60)
        #expect(config.refreshCadence == .oneMinute)
        #expect(!config.healthShiftAlertsEnabled)
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

        #expect(!config.healthShiftAlertsEnabled)
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
            healthShiftAlertsEnabled: true
        )

        try store.save(config)

        #expect(try store.load() == config)
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
}
