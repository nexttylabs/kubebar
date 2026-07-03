import Foundation

public struct WarningEventDiagnosticReadRequest: Equatable, Sendable {
    public let target: WarningEventDiagnosticTarget
    public let limit: Int
    public let command: CommandRequest

    public init(
        target: WarningEventDiagnosticTarget,
        config: AppConfig,
        limit: Int = 5,
        kubectlEnvironment: KubectlEnvironment? = nil
    ) {
        self.target = target
        self.limit = limit
        let environment = kubectlEnvironment ?? KubectlEnvironment(config: config)
        self.command = CommandRequest(
            executable: "kubectl",
            arguments: [
                "--context", target.contextName,
                "get", "events",
                "--all-namespaces",
                "--field-selector", "type=Warning",
                "-o", "json"
            ],
            environmentOverrides: environment.environmentOverrides,
            timeoutSeconds: 10
        )
    }

    init(target: WarningEventDiagnosticTarget, limit: Int = 5, command: CommandRequest) {
        self.target = target
        self.limit = limit
        self.command = command
    }
}

public enum WarningEventDiagnosticReadError: Error, Equatable, Sendable {
    case launchFailed
    case timedOut
    case invalidJSON
    case commandFailed(String)
    case noMatchingEvents
}

extension WarningEventDiagnosticReadError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .launchFailed:
            "kubectl events failed to launch"
        case .timedOut:
            "kubectl events timed out"
        case .invalidJSON:
            "invalid event JSON"
        case let .commandFailed(message):
            message
        case .noMatchingEvents:
            "No matching warning events were found. Refresh and try again."
        }
    }
}

public protocol WarningEventDiagnosticReading: Sendable {
    func readEvents(for request: WarningEventDiagnosticReadRequest) async throws -> [WarningEventRecord]
}

public struct CommandWarningEventDiagnosticReader: WarningEventDiagnosticReading, Sendable {
    private let runner: any CommandRunning

    public init(runner: any CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func readEvents(for request: WarningEventDiagnosticReadRequest) async throws -> [WarningEventRecord] {
        let runner = runner
        return try await Task.detached(priority: .userInitiated) {
            do {
                let result = try runner.run(request.command)
                guard result.exitCode == 0 else {
                    throw WarningEventDiagnosticReadError.commandFailed(
                        Self.safeFailureDetail(from: result.stderr)
                    )
                }

                let records = try Self.decodeWarningEvents(result.stdout)
                let matches = records
                    .filter(request.target.matches)
                    .sorted(by: Self.newestFirst)
                    .prefix(max(1, request.limit))

                guard !matches.isEmpty else {
                    throw WarningEventDiagnosticReadError.noMatchingEvents
                }

                return Array(matches)
            } catch CommandRunnerError.launchFailed {
                throw WarningEventDiagnosticReadError.launchFailed
            } catch CommandRunnerError.timedOut {
                throw WarningEventDiagnosticReadError.timedOut
            }
        }.value
    }

    private static func newestFirst(_ left: WarningEventRecord, _ right: WarningEventRecord) -> Bool {
        let leftDate = left.observedAt ?? .distantPast
        let rightDate = right.observedAt ?? .distantPast

        if leftDate != rightDate {
            return leftDate > rightDate
        }

        if left.reason != right.reason {
            return left.reason < right.reason
        }

        return (left.message ?? "") < (right.message ?? "")
    }

    private static func decodeWarningEvents(_ json: String) throws -> [WarningEventRecord] {
        do {
            return try JSONDecoder()
                .decode(EventList.self, from: Data(json.utf8))
                .items
                .map(makeWarningEventRecord)
        } catch let error as WarningEventDiagnosticReadError {
            throw error
        } catch {
            throw WarningEventDiagnosticReadError.invalidJSON
        }
    }

    private static func makeWarningEventRecord(_ event: EventRecord) -> WarningEventRecord {
        let object = event.involvedObject ?? event.regarding
        let reason = normalizedText(event.reason) ?? "Unknown"
        let count = max(1, event.series?.count ?? event.deprecatedCount ?? event.count ?? 1)

        return WarningEventRecord(
            reason: reason,
            namespace: normalizedText(object?.namespace) ?? normalizedText(event.metadata?.namespace),
            objectKind: normalizedText(object?.kind),
            objectName: normalizedText(object?.name),
            message: normalizedText(event.message) ?? normalizedText(event.note),
            observedAt: parsedTimestamp([
                event.series?.lastObservedTime,
                event.deprecatedLastTimestamp,
                event.lastTimestamp,
                event.eventTime,
                event.metadata?.creationTimestamp
            ]),
            count: count
        )
    }

    private static func parsedTimestamp(_ values: [String?]) -> Date? {
        for value in values.compactMap({ normalizedText($0) }) {
            if let date = parsedTimestamp(value) {
                return date
            }
        }

        return nil
    }

    private static func parsedTimestamp(_ value: String) -> Date? {
        let standardFormatter = ISO8601DateFormatter()
        if let date = standardFormatter.date(from: value) {
            return date
        }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractionalFormatter.date(from: value)
    }

    private static func normalizedText(_ value: String?) -> String? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, !text.isEmpty else {
            return nil
        }

        return text
    }

    private static func safeFailureDetail(from stderr: String) -> String {
        let trimmed = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "kubectl events failed"
        }

        if containsSensitiveMarker(trimmed) {
            return "kubectl events failed"
        }

        if let range = trimmed.range(of: "): ") {
            return String(trimmed[range.upperBound...])
        }

        guard trimmed.count > 96 else {
            return trimmed
        }

        return String(trimmed.prefix(96))
    }

    private static func containsSensitiveMarker(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return [
            "token",
            "password",
            "client-key-data",
            "client-certificate-data",
            "certificate-authority-data",
            "authorization",
            "bearer"
        ].contains { lowercased.contains($0) }
    }
}

private struct EventList: Decodable {
    let items: [EventRecord]
}

private struct EventRecord: Decodable {
    struct Metadata: Decodable {
        let namespace: String?
        let creationTimestamp: String?
    }

    struct ObjectReference: Decodable {
        let kind: String?
        let namespace: String?
        let name: String?
    }

    struct Series: Decodable {
        let count: Int?
        let lastObservedTime: String?
    }

    let metadata: Metadata?
    let reason: String?
    let message: String?
    let note: String?
    let involvedObject: ObjectReference?
    let regarding: ObjectReference?
    let lastTimestamp: String?
    let eventTime: String?
    let count: Int?
    let deprecatedCount: Int?
    let deprecatedLastTimestamp: String?
    let series: Series?
}
