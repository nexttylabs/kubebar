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
    }

    @Test("saved context and watchlist round trip")
    func savedContextAndWatchlistRoundTrip() throws {
        let store = AppConfigStore(directory: makeTemporaryDirectory())
        let config = AppConfig(
            selectedContext: "prod",
            watchTargets: [
                .workload(namespace: "api", name: "checkout"),
                .namespace("monitoring")
            ],
            refreshIntervalSeconds: 60
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

    private func makeTemporaryDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("kubebar-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
