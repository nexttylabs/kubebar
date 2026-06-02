import Foundation

public struct AppConfig: Codable, Equatable, Sendable {
    public let selectedContext: String?
    public let watchTargets: [WatchTarget]
    public let refreshIntervalSeconds: Int
    public let healthShiftAlertsEnabled: Bool

    private enum CodingKeys: String, CodingKey {
        case selectedContext
        case watchTargets
        case refreshIntervalSeconds
        case healthShiftAlertsEnabled
    }

    public init(
        selectedContext: String? = nil,
        watchTargets: [WatchTarget] = [],
        refreshIntervalSeconds: Int = RefreshCadence.default.seconds,
        healthShiftAlertsEnabled: Bool = false
    ) {
        self.selectedContext = selectedContext
        self.watchTargets = watchTargets
        self.refreshIntervalSeconds = RefreshCadence.from(seconds: refreshIntervalSeconds).seconds
        self.healthShiftAlertsEnabled = healthShiftAlertsEnabled
    }

    public var needsSetup: Bool {
        selectedContext == nil || watchTargets.isEmpty
    }

    public var refreshCadence: RefreshCadence {
        RefreshCadence.from(seconds: refreshIntervalSeconds)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            selectedContext: try container.decodeIfPresent(String.self, forKey: .selectedContext),
            watchTargets: try container.decodeIfPresent([WatchTarget].self, forKey: .watchTargets) ?? [],
            refreshIntervalSeconds: try container.decodeIfPresent(Int.self, forKey: .refreshIntervalSeconds) ?? RefreshCadence.default.seconds,
            healthShiftAlertsEnabled: try container.decodeIfPresent(Bool.self, forKey: .healthShiftAlertsEnabled) ?? false
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(selectedContext, forKey: .selectedContext)
        try container.encode(watchTargets, forKey: .watchTargets)
        try container.encode(refreshIntervalSeconds, forKey: .refreshIntervalSeconds)
        try container.encode(healthShiftAlertsEnabled, forKey: .healthShiftAlertsEnabled)
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
