import Foundation

public struct AppConfig: Codable, Equatable, Sendable {
    public let selectedContext: String?
    public let watchTargets: [WatchTarget]
    public let refreshIntervalSeconds: Int

    public init(
        selectedContext: String? = nil,
        watchTargets: [WatchTarget] = [],
        refreshIntervalSeconds: Int = 60
    ) {
        self.selectedContext = selectedContext
        self.watchTargets = watchTargets
        self.refreshIntervalSeconds = refreshIntervalSeconds
    }

    public var needsSetup: Bool {
        selectedContext == nil || watchTargets.isEmpty
    }
}

public enum AppConfigStoreError: Error, Equatable {
    case corruptConfig
    case cannotSave
}

public struct AppConfigStore {
    private let directory: URL
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        directory: URL,
        fileManager: FileManager = .default,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.directory = directory
        self.fileManager = fileManager
        self.decoder = decoder
        self.encoder = encoder
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load() throws -> AppConfig {
        let url = configURL

        guard fileManager.fileExists(atPath: url.path) else {
            return AppConfig()
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(AppConfig.self, from: data)
        } catch {
            throw AppConfigStoreError.corruptConfig
        }
    }

    public func save(_ config: AppConfig) throws {
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try encoder.encode(config)
            try data.write(to: configURL, options: .atomic)
        } catch {
            throw AppConfigStoreError.cannotSave
        }
    }

    private var configURL: URL {
        directory.appendingPathComponent("config.json")
    }
}
