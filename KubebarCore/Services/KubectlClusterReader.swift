import Foundation

public protocol ClusterReading: Sendable {
    func readSnapshot(contextName: String, watchTargets: [WatchTarget], now: Date) throws -> ClusterSnapshot
}

public struct KubectlClusterReader: ClusterReading, Sendable {
    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func readSnapshot(contextName: String, watchTargets: [WatchTarget], now: Date) throws -> ClusterSnapshot {
        let rawSnapshot = readRawSnapshot(contextName: contextName)
        let nodesSection = decodedSection(rawSnapshot.result(for: .nodes), decode: decodeNodes)
        let podRecordsSection = decodedSection(rawSnapshot.result(for: .pods), decode: decodePods)
        let podsSection = mappedSection(podRecordsSection) { pods in
            PodSummary(running: pods.filter(\.isRunning).count, total: pods.count)
        }
        let warningEventsSection = decodedSection(rawSnapshot.result(for: .warningEvents), decode: decodeWarningEvents)
        let workloadsSection = mappedSection(podRecordsSection) { pods in
            watchTargets.map { target in trackedStatus(for: target, pods: pods) }
        }

        guard nodesSection.isAvailable || podsSection.isAvailable || warningEventsSection.isAvailable || workloadsSection.isAvailable else {
            throw KubectlCommandError.failed(
                nodesSection.unavailableReason ??
                    podsSection.unavailableReason ??
                    warningEventsSection.unavailableReason ??
                    workloadsSection.unavailableReason ??
                    "kubectl failed"
            )
        }

        return ClusterSnapshot(
            contextName: contextName,
            nodesSection: nodesSection,
            podsSection: podsSection,
            warningEventsSection: warningEventsSection,
            workloadsSection: workloadsSection,
            capturedAt: now
        )
    }

    private func readRawSnapshot(contextName: String) -> RawKubectlSnapshot {
        let results = LockedKubectlResults()
        let group = DispatchGroup()

        for read in KubectlRead.allCases {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let output = try runKubectl(contextName: contextName, arguments: read.arguments)
                    results.set(.success(output), for: read)
                } catch let error as KubectlCommandError {
                    results.set(.failure(error), for: read)
                } catch {
                    results.set(.failure(.failed(error.localizedDescription)), for: read)
                }
                group.leave()
            }
        }

        group.wait()

        let outputs = Dictionary(
            uniqueKeysWithValues: KubectlRead.allCases.map { read in
                (read, results.result(for: read) ?? .failure(.failed("kubectl failed")))
            }
        )

        return RawKubectlSnapshot(results: outputs)
    }

    private func runKubectl(contextName: String, arguments: [String]) throws -> String {
        let result: CommandResult
        do {
            result = try runner.run(
                CommandRequest(executable: "kubectl", arguments: ["--context", contextName] + arguments)
            )
        } catch CommandRunnerError.timedOut {
            throw KubectlCommandError.failed("kubectl timed out")
        } catch CommandRunnerError.launchFailed {
            throw KubectlCommandError.failed("kubectl could not be launched")
        }

        guard result.exitCode == 0 else {
            throw KubectlCommandError.failed(displaySafeFailureReason(result.standardError))
        }

        return result.standardOutput
    }

    private func decodedSection<Value: Equatable & Sendable>(
        _ result: Result<String, KubectlCommandError>?,
        decode: (String) throws -> Value
    ) -> SnapshotSection<Value> {
        guard let result else {
            return .unavailable(reason: "kubectl failed")
        }

        do {
            return .available(try decode(try result.get()))
        } catch let error as KubectlCommandError {
            return .unavailable(reason: displaySafeFailureReason(error.reason))
        } catch {
            return .unavailable(reason: displaySafeFailureReason(error.localizedDescription))
        }
    }

    private func mappedSection<Input: Equatable & Sendable, Output: Equatable & Sendable>(
        _ section: SnapshotSection<Input>,
        transform: (Input) -> Output
    ) -> SnapshotSection<Output> {
        switch section {
        case let .available(value):
            .available(transform(value))
        case let .unavailable(reason):
            .unavailable(reason: reason)
        }
    }

    private func decodeNodes(_ json: String) throws -> NodeSummary {
        do {
            let nodeList = try JSONDecoder().decode(NodeList.self, from: Data(json.utf8))
            let ready = nodeList.items.filter(\.isReady).count
            return NodeSummary(ready: ready, total: nodeList.items.count)
        } catch {
            throw KubectlCommandError.failed("invalid node JSON")
        }
    }

    private func decodePods(_ json: String) throws -> [PodRecord] {
        do {
            return try JSONDecoder().decode(PodList.self, from: Data(json.utf8)).items
        } catch {
            throw KubectlCommandError.failed("invalid pod JSON")
        }
    }

    private func decodeWarningEvents(_ json: String) throws -> [WarningEventRecord] {
        do {
            return try JSONDecoder()
                .decode(EventList.self, from: Data(json.utf8))
                .items
                .map(makeWarningEventRecord)
        } catch {
            throw KubectlCommandError.failed("invalid event JSON")
        }
    }

    private func trackedStatus(for target: WatchTarget, pods: [PodRecord]) -> TrackedItemStatus {
        let matchingPods = pods.filter { pod in
            switch target {
            case let .namespace(namespace):
                pod.metadata.namespace == namespace
            case let .workload(namespace, name, _):
                pod.metadata.namespace == namespace && pod.matchesWorkload(named: name)
            }
        }

        guard !matchingPods.isEmpty else {
            return TrackedItemStatus(target: target, state: .bad, reason: "no matching pods")
        }

        let running = matchingPods.filter(\.isRunning).count
        let reason = "\(running)/\(matchingPods.count) pods running"
        return TrackedItemStatus(
            target: target,
            state: running == matchingPods.count ? .ok : .bad,
            reason: reason
        )
    }

    private func makeWarningEventRecord(_ event: EventRecord) -> WarningEventRecord {
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

    private func parsedTimestamp(_ values: [String?]) -> Date? {
        for value in values.compactMap({ normalizedText($0) }) {
            if let date = parsedTimestamp(value) {
                return date
            }
        }

        return nil
    }

    private func parsedTimestamp(_ value: String) -> Date? {
        let standardFormatter = ISO8601DateFormatter()
        if let date = standardFormatter.date(from: value) {
            return date
        }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractionalFormatter.date(from: value)
    }

    private func normalizedText(_ value: String?) -> String? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, !text.isEmpty else {
            return nil
        }

        return text
    }

    private func displaySafeFailureReason(_ raw: String) -> String {
        let firstLine = raw
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "kubectl failed"
        let homeRedacted = firstLine
            .replacingOccurrences(of: NSHomeDirectory(), with: "~")
            .replacingOccurrences(of: #"/Users/[^/\s]+"#, with: "~", options: .regularExpression)
        let lowercased = homeRedacted.lowercased()
        let sensitiveMarkers = [
            "token",
            "password",
            "client-key-data",
            "client-certificate-data",
            "certificate-authority-data"
        ]

        guard !sensitiveMarkers.contains(where: { lowercased.contains($0) }) else {
            return "kubectl failed"
        }

        guard homeRedacted.count > 96 else {
            return homeRedacted
        }

        return String(homeRedacted.prefix(96))
    }
}

private extension KubectlCommandError {
    var reason: String {
        switch self {
        case let .failed(reason):
            reason
        }
    }
}

private enum KubectlRead: CaseIterable, Hashable, Sendable {
    case nodes
    case pods
    case warningEvents

    var arguments: [String] {
        switch self {
        case .nodes:
            return ["get", "nodes", "-o", "json"]
        case .pods:
            return ["get", "pods", "--all-namespaces", "-o", "json"]
        case .warningEvents:
            return ["get", "events", "--all-namespaces", "--field-selector", "type=Warning", "-o", "json"]
        }
    }
}

private struct RawKubectlSnapshot: Sendable {
    let results: [KubectlRead: Result<String, KubectlCommandError>]

    func result(for read: KubectlRead) -> Result<String, KubectlCommandError>? {
        results[read]
    }
}

private final class LockedKubectlResults: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [KubectlRead: Result<String, KubectlCommandError>] = [:]

    func set(_ result: Result<String, KubectlCommandError>, for read: KubectlRead) {
        lock.lock()
        storage[read] = result
        lock.unlock()
    }

    func result(for read: KubectlRead) -> Result<String, KubectlCommandError>? {
        lock.lock()
        defer { lock.unlock() }
        return storage[read]
    }
}

private struct NodeList: Decodable {
    let items: [NodeRecord]
}

private struct NodeRecord: Decodable {
    struct Status: Decodable {
        let conditions: [Condition]
    }

    struct Condition: Decodable {
        let type: String
        let status: String
    }

    let status: Status

    var isReady: Bool {
        status.conditions.contains { $0.type == "Ready" && $0.status == "True" }
    }
}

private struct PodList: Decodable {
    let items: [PodRecord]
}

private struct PodRecord: Decodable, Equatable, Sendable {
    struct Metadata: Decodable, Equatable, Sendable {
        let namespace: String
        let name: String
        let labels: [String: String]?
    }

    struct Status: Decodable, Equatable, Sendable {
        let phase: String
    }

    let metadata: Metadata
    let status: Status

    var isRunning: Bool {
        status.phase == "Running"
    }

    func matchesWorkload(named name: String) -> Bool {
        metadata.name == name ||
            metadata.labels?["app.kubernetes.io/name"] == name ||
            metadata.labels?["app"] == name
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
