import Foundation

public struct AppConfig: Codable, Equatable, Sendable {
    public let selectedContext: String?
    public let watchlistsByContext: [String: [WatchTarget]]
    public let refreshIntervalSeconds: Int
    public let healthShiftAlertsEnabled: Bool
    public let kubeconfigPaths: [String]
    public let aiDiagnosticAssistant: AIDiagnosticAssistantConfig

    private enum CodingKeys: String, CodingKey {
        case selectedContext
        case watchlistsByContext
        case watchTargets
        case refreshIntervalSeconds
        case healthShiftAlertsEnabled
        case kubeconfigPaths
        case aiDiagnosticAssistant
    }

    public init(
        selectedContext: String? = nil,
        watchTargets: [WatchTarget] = [],
        watchlistsByContext: [String: [WatchTarget]]? = nil,
        refreshIntervalSeconds: Int = RefreshCadence.default.seconds,
        healthShiftAlertsEnabled: Bool = false,
        kubeconfigPaths: [String] = [],
        aiDiagnosticAssistant: AIDiagnosticAssistantConfig = AIDiagnosticAssistantConfig()
    ) {
        self.selectedContext = selectedContext
        if let watchlistsByContext {
            self.watchlistsByContext = watchlistsByContext
        } else if let selectedContext, !watchTargets.isEmpty {
            self.watchlistsByContext = [selectedContext: watchTargets]
        } else {
            self.watchlistsByContext = [:]
        }
        self.refreshIntervalSeconds = RefreshCadence.from(seconds: refreshIntervalSeconds).seconds
        self.healthShiftAlertsEnabled = healthShiftAlertsEnabled
        self.kubeconfigPaths = kubeconfigPaths
        self.aiDiagnosticAssistant = aiDiagnosticAssistant
    }

    public var watchTargets: [WatchTarget] {
        guard let selectedContext else {
            return []
        }

        return watchlistsByContext[selectedContext] ?? []
    }

    public var needsSetup: Bool {
        selectedContext == nil || watchTargets.isEmpty
    }

    public var refreshCadence: RefreshCadence {
        RefreshCadence.from(seconds: refreshIntervalSeconds)
    }

    public func selectingContext(_ context: String) -> AppConfig {
        AppConfig(
            selectedContext: context,
            watchlistsByContext: watchlistsByContext,
            refreshIntervalSeconds: refreshIntervalSeconds,
            healthShiftAlertsEnabled: healthShiftAlertsEnabled,
            kubeconfigPaths: kubeconfigPaths,
            aiDiagnosticAssistant: aiDiagnosticAssistant
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            selectedContext: try container.decodeIfPresent(String.self, forKey: .selectedContext),
            watchTargets: try container.decodeIfPresent([WatchTarget].self, forKey: .watchTargets) ?? [],
            watchlistsByContext: try Self.decodedWatchlists(from: container),
            refreshIntervalSeconds: try container.decodeIfPresent(Int.self, forKey: .refreshIntervalSeconds) ?? RefreshCadence.default.seconds,
            healthShiftAlertsEnabled: try container.decodeIfPresent(Bool.self, forKey: .healthShiftAlertsEnabled) ?? false,
            kubeconfigPaths: try container.decodeIfPresent([String].self, forKey: .kubeconfigPaths) ?? [],
            aiDiagnosticAssistant: try container.decodeIfPresent(AIDiagnosticAssistantConfig.self, forKey: .aiDiagnosticAssistant) ?? AIDiagnosticAssistantConfig()
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(selectedContext, forKey: .selectedContext)
        try container.encode(watchlistsByContext, forKey: .watchlistsByContext)
        try container.encode(watchTargets, forKey: .watchTargets)
        try container.encode(refreshIntervalSeconds, forKey: .refreshIntervalSeconds)
        try container.encode(healthShiftAlertsEnabled, forKey: .healthShiftAlertsEnabled)
        try container.encode(kubeconfigPaths, forKey: .kubeconfigPaths)
        try container.encode(aiDiagnosticAssistant, forKey: .aiDiagnosticAssistant)
    }

    private static func decodedWatchlists(from container: KeyedDecodingContainer<CodingKeys>) throws -> [String: [WatchTarget]]? {
        if let watchlistsByContext = try container.decodeIfPresent([String: [WatchTarget]].self, forKey: .watchlistsByContext) {
            return watchlistsByContext
        }

        guard let selectedContext = try container.decodeIfPresent(String.self, forKey: .selectedContext),
              let legacyWatchTargets = try container.decodeIfPresent([WatchTarget].self, forKey: .watchTargets),
              !legacyWatchTargets.isEmpty else {
            return nil
        }

        return [selectedContext: legacyWatchTargets]
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
