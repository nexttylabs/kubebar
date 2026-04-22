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
        let rawSnapshot = readRawSnapshot(contextName: contextName, watchTargets: watchTargets)
        let nodeRecordsSection = decodedSection(rawSnapshot.result(for: .nodes), decode: decodeNodeRecords)
        let nodesSection = mappedSection(nodeRecordsSection, transform: makeNodeSummary)
        let metricsRecordsSection = decodedSection(rawSnapshot.result(for: .nodeMetrics), decode: decodeNodeMetrics)
        let nodeDetailsSection = makeNodeDetailsSection(
            nodeRecordsSection: nodeRecordsSection,
            metricsRecordsSection: metricsRecordsSection
        )
        let podRecordsSection = decodedSection(rawSnapshot.result(for: .pods), decode: decodePods)
        let podsSection = mappedSection(podRecordsSection, transform: makePodSummary)
        let metricsSection = makeMetricsSection(
            nodeRecordsSection: nodeRecordsSection,
            metricsRecordsSection: metricsRecordsSection
        )
        let warningEventsSection = decodedSection(rawSnapshot.result(for: .warningEvents), decode: decodeWarningEvents)
        let workloadSelectorsSection = decodeWorkloadSelectors(from: rawSnapshot, watchTargets: watchTargets)
        let workloadsSection = trackedItemsSection(
            podRecordsSection: podRecordsSection,
            workloadSelectorsSection: workloadSelectorsSection,
            warningEvents: warningEventsSection.value ?? [],
            watchTargets: watchTargets
        )

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
            nodeDetailsSection: nodeDetailsSection,
            podsSection: podsSection,
            metricsSection: metricsSection,
            warningEventsSection: warningEventsSection,
            workloadsSection: workloadsSection,
            capturedAt: now
        )
    }

    private func readRawSnapshot(contextName: String, watchTargets: [WatchTarget]) -> RawKubectlSnapshot {
        let reads = KubectlRead.reads(for: watchTargets)
        let results = LockedKubectlResults()
        let group = DispatchGroup()

        for read in reads {
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
            uniqueKeysWithValues: reads.map { read in
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

    private func decodeNodeRecords(_ json: String) throws -> [NodeRecord] {
        do {
            return try JSONDecoder().decode(NodeList.self, from: Data(json.utf8)).items
        } catch {
            throw KubectlCommandError.failed("invalid node JSON")
        }
    }

    private func makeNodeSummary(from nodes: [NodeRecord]) -> NodeSummary {
        NodeSummary(ready: nodes.filter(\.isReady).count, total: nodes.count)
    }

    private func makePodSummary(from pods: [PodRecord]) -> PodSummary {
        PodSummary(
            ready: pods.filter { !$0.isNotReady }.count,
            running: pods.filter(\.isRunning).count,
            total: pods.count
        )
    }

    private func decodePods(_ json: String) throws -> [PodRecord] {
        do {
            return try JSONDecoder().decode(PodList.self, from: Data(json.utf8)).items
        } catch {
            throw KubectlCommandError.failed("invalid pod JSON")
        }
    }

    private func decodeNodeMetrics(_ json: String) throws -> [NodeMetricsRecord] {
        do {
            return try JSONDecoder().decode(NodeMetricsList.self, from: Data(json.utf8)).items
        } catch {
            throw KubectlCommandError.failed("invalid metrics JSON")
        }
    }

    private func makeMetricsSection(
        nodeRecordsSection: SnapshotSection<[NodeRecord]>,
        metricsRecordsSection: SnapshotSection<[NodeMetricsRecord]>
    ) -> SnapshotSection<ClusterMetricsSummary> {
        guard let nodes = nodeRecordsSection.value else {
            return .unavailable(reason: nodeRecordsSection.unavailableReason ?? "Node data unavailable")
        }

        guard let metrics = metricsRecordsSection.value else {
            return .unavailable(reason: metricsRecordsSection.unavailableReason ?? "Metrics unavailable")
        }

        guard
            let cpuAllocatable = sumNodeQuantity(nodes, resource: "cpu", scale: .cpuNanocores),
            let memoryAllocatable = sumNodeQuantity(nodes, resource: "memory", scale: .memoryBytes),
            cpuAllocatable > 0,
            memoryAllocatable > 0
        else {
            return .unavailable(reason: "missing node allocatable")
        }

        guard
            let cpuUsage = sumMetricQuantity(metrics, resource: "cpu", scale: .cpuNanocores),
            let memoryUsage = sumMetricQuantity(metrics, resource: "memory", scale: .memoryBytes)
        else {
            return .unavailable(reason: "invalid metrics JSON")
        }

        return .available(
            ClusterMetricsSummary(
                cpuUsageNanocores: cpuUsage,
                cpuAllocatableNanocores: cpuAllocatable,
                memoryUsageBytes: memoryUsage,
                memoryAllocatableBytes: memoryAllocatable
            )
        )
    }

    private func makeNodeDetailsSection(
        nodeRecordsSection: SnapshotSection<[NodeRecord]>,
        metricsRecordsSection: SnapshotSection<[NodeMetricsRecord]>
    ) -> SnapshotSection<[NodeDetail]> {
        guard let nodes = nodeRecordsSection.value else {
            return .unavailable(reason: nodeRecordsSection.unavailableReason ?? "Node data unavailable")
        }

        let metricsByName = (metricsRecordsSection.value ?? []).reduce(into: [String: NodeMetricsRecord]()) { result, record in
            result[record.metadata.name] = record
        }

        return .available(
            nodes.map { node in
                let name = node.metadata.name
                let metrics = metricsByName[name]
                let cpuAllocatable = parseNodeQuantity(node, resource: "cpu", scale: .cpuNanocores)
                let memoryAllocatable = parseNodeQuantity(node, resource: "memory", scale: .memoryBytes)
                let cpuUsage = parseMetricQuantity(metrics, resource: "cpu", scale: .cpuNanocores)
                let memoryUsage = parseMetricQuantity(metrics, resource: "memory", scale: .memoryBytes)
                let issue = node.healthIssue

                return NodeDetail(
                    name: name,
                    isReady: node.isReady,
                    issueReason: issue.reason,
                    issueMessage: issue.message,
                    cpuUsageNanocores: cpuUsage,
                    cpuAllocatableNanocores: cpuAllocatable,
                    memoryUsageBytes: memoryUsage,
                    memoryAllocatableBytes: memoryAllocatable
                )
            }
        )
    }

    private func sumNodeQuantity(_ nodes: [NodeRecord], resource: String, scale: ResourceQuantityScale) -> Int64? {
        sumQuantities(nodes.map { $0.status.allocatable?[resource] }, scale: scale)
    }

    private func sumMetricQuantity(_ metrics: [NodeMetricsRecord], resource: String, scale: ResourceQuantityScale) -> Int64? {
        sumQuantities(metrics.map { $0.usage[resource] }, scale: scale)
    }

    private func parseNodeQuantity(_ node: NodeRecord, resource: String, scale: ResourceQuantityScale) -> Int64? {
        guard let value = node.status.allocatable?[resource] else {
            return nil
        }

        return parseResourceQuantity(value, scale: scale)
    }

    private func parseMetricQuantity(_ metrics: NodeMetricsRecord?, resource: String, scale: ResourceQuantityScale) -> Int64? {
        guard let value = metrics?.usage[resource] else {
            return nil
        }

        return parseResourceQuantity(value, scale: scale)
    }

    private func sumQuantities(_ values: [String?], scale: ResourceQuantityScale) -> Int64? {
        var total: Int64 = 0

        for value in values {
            guard let value, let parsed = parseResourceQuantity(value, scale: scale) else {
                return nil
            }

            let nextTotal = total.addingReportingOverflow(parsed)
            if nextTotal.overflow {
                return nil
            }

            total = nextTotal.partialValue
        }

        return total
    }

    private func parseResourceQuantity(_ value: String, scale: ResourceQuantityScale) -> Int64? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let number = Double(trimmed), number >= 0, number.isFinite {
            return scaledQuantity(number: number, multiplier: scale.multiplier(for: ""))
        }

        let splitIndex = trimmed.firstIndex { character in
            !(character.isNumber || character == "." || character == "+" || character == "-")
        } ?? trimmed.endIndex
        let numberText = String(trimmed[..<splitIndex])
        let suffix = String(trimmed[splitIndex...])

        guard
            let number = Double(numberText),
            number >= 0,
            number.isFinite,
            let multiplier = scale.multiplier(for: suffix)
        else {
            return nil
        }

        return scaledQuantity(number: number, multiplier: multiplier)
    }

    private func scaledQuantity(number: Double, multiplier: Double?) -> Int64? {
        guard let multiplier else {
            return nil
        }

        let scaled = number * multiplier
        guard scaled.isFinite, scaled <= Double(Int64.max) else {
            return nil
        }

        return Int64(scaled.rounded(.toNearestOrAwayFromZero))
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

    private func decodeWorkloadMetadata(_ json: String, kind: WorkloadKind) throws -> [WorkloadMetadataRecord] {
        do {
            return try JSONDecoder()
                .decode(WorkloadMetadataList.self, from: Data(json.utf8))
                .items
                .map { $0.with(kind: kind) }
        } catch {
            throw KubectlCommandError.failed("invalid workload JSON")
        }
    }

    private func decodeWorkloadSelectors(
        from rawSnapshot: RawKubectlSnapshot,
        watchTargets: [WatchTarget]
    ) -> SnapshotSection<[WorkloadIdentity: [String: String]]> {
        var selectors: [WorkloadIdentity: [String: String]] = [:]

        for kind in selectorBackedKinds(for: watchTargets) {
            let section = decodedSection(rawSnapshot.result(for: .workload(kind))) { json in
                try decodeWorkloadMetadata(json, kind: kind)
            }

            switch section {
            case let .available(records):
                for record in records {
                    guard let matchLabels = record.spec.selector?.matchLabels, !matchLabels.isEmpty else {
                        continue
                    }

                    selectors[record.identity] = matchLabels
                }
            case let .unavailable(reason):
                return .unavailable(reason: reason)
            }
        }

        return .available(selectors)
    }

    private func selectorBackedKinds(for watchTargets: [WatchTarget]) -> [WorkloadKind] {
        let targetKinds = Set(watchTargets.compactMap { target -> WorkloadKind? in
            guard case let .workload(_, _, kind) = target, kind.supportsSelectorMetadata else {
                return nil
            }

            return kind
        })

        return WorkloadKind.allCases.filter { targetKinds.contains($0) }
    }

    private func trackedItemsSection(
        podRecordsSection: SnapshotSection<[PodRecord]>,
        workloadSelectorsSection: SnapshotSection<[WorkloadIdentity: [String: String]]>,
        warningEvents: [WarningEventRecord],
        watchTargets: [WatchTarget]
    ) -> SnapshotSection<[TrackedItemStatus]> {
        guard let pods = podRecordsSection.value else {
            return .unavailable(reason: podRecordsSection.unavailableReason ?? "invalid pod JSON")
        }

        guard let workloadSelectors = workloadSelectorsSection.value else {
            return .unavailable(reason: workloadSelectorsSection.unavailableReason ?? "invalid workload JSON")
        }

        return .available(
            watchTargets.map { target in
                trackedStatus(
                    for: target,
                    pods: pods,
                    warningEvents: warningEvents,
                    workloadSelectors: workloadSelectors
                )
            }
        )
    }

    private func trackedStatus(
        for target: WatchTarget,
        pods: [PodRecord],
        warningEvents: [WarningEventRecord],
        workloadSelectors: [WorkloadIdentity: [String: String]]
    ) -> TrackedItemStatus {
        let matchingPods = pods.filter { pod in
            pod.matches(target: target, workloadSelectors: workloadSelectors)
        }
        let latestWarning = latestRelatedWarning(for: target, matchingPods: matchingPods, warningEvents: warningEvents)

        guard !matchingPods.isEmpty else {
            return TrackedItemStatus(
                target: target,
                state: .bad,
                reason: "no matching pods",
                affectedPodCount: 0,
                latestWarning: latestWarning
            )
        }

        let failedPods = matchingPods.filter(\.isFailed)
        if !failedPods.isEmpty {
            return TrackedItemStatus(
                target: target,
                state: .bad,
                reason: podReason(count: failedPods.count, suffix: "failed"),
                affectedPodCount: failedPods.count,
                examplePodNames: examplePodNames(from: failedPods),
                latestWarning: latestWarning
            )
        }

        let restartingPods = matchingPods.filter(\.isRestarting)
        if !restartingPods.isEmpty {
            return TrackedItemStatus(
                target: target,
                state: .bad,
                reason: podReason(count: restartingPods.count, suffix: "restarting"),
                affectedPodCount: restartingPods.count,
                examplePodNames: examplePodNames(from: restartingPods),
                latestWarning: latestWarning
            )
        }

        let notReadyPods = matchingPods.filter(\.isNotReady)
        if !notReadyPods.isEmpty {
            return TrackedItemStatus(
                target: target,
                state: .watch,
                reason: podReason(count: notReadyPods.count, suffix: "not ready"),
                affectedPodCount: notReadyPods.count,
                examplePodNames: examplePodNames(from: notReadyPods),
                latestWarning: latestWarning
            )
        }

        if let latestWarning {
            return TrackedItemStatus(
                target: target,
                state: .watch,
                reason: "latest warning: \(latestWarning.reason)",
                latestWarning: latestWarning
            )
        }

        let running = matchingPods.filter(\.isRunning).count
        let reason = "\(running)/\(matchingPods.count) pods running"
        return TrackedItemStatus(
            target: target,
            state: running == matchingPods.count ? .ok : .bad,
            reason: reason
        )
    }

    private func podReason(count: Int, suffix: String) -> String {
        count == 1 ? "1 pod \(suffix)" : "\(count) pods \(suffix)"
    }

    private func examplePodNames(from pods: [PodRecord]) -> [String] {
        Array(pods.map(\.metadata.name).sorted().prefix(3))
    }

    private func latestRelatedWarning(
        for target: WatchTarget,
        matchingPods: [PodRecord],
        warningEvents: [WarningEventRecord]
    ) -> WarningEventRecord? {
        switch target {
        case let .namespace(namespace):
            return newestWarning(warningEvents.filter { $0.namespace == namespace })
        case let .workload(namespace, name, kind):
            let matchingPodNames = Set(matchingPods.map(\.metadata.name))
            let podWarnings = warningEvents.filter { event in
                event.namespace == namespace && event.objectName.map { matchingPodNames.contains($0) } == true
            }

            if let newestPodWarning = newestWarning(podWarnings) {
                return newestPodWarning
            }

            return newestWarning(warningEvents.filter { event in
                event.namespace == namespace &&
                    event.objectName == name &&
                    event.objectKind == kind.displayName
            })
        }
    }

    private func newestWarning(_ warningEvents: [WarningEventRecord]) -> WarningEventRecord? {
        warningEvents.max { left, right in
            let leftDate = left.observedAt ?? .distantPast
            let rightDate = right.observedAt ?? .distantPast

            if leftDate != rightDate {
                return leftDate < rightDate
            }

            return left.reason < right.reason
        }
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

private extension WorkloadKind {
    var supportsSelectorMetadata: Bool {
        switch self {
        case .deployment, .statefulSet, .daemonSet:
            true
        case .cronJob:
            false
        }
    }
}

private enum KubectlRead: Hashable, Sendable {
    case nodes
    case pods
    case nodeMetrics
    case warningEvents
    case workload(WorkloadKind)

    var arguments: [String] {
        switch self {
        case .nodes:
            return ["get", "nodes", "-o", "json"]
        case .pods:
            return ["get", "pods", "--all-namespaces", "-o", "json"]
        case .nodeMetrics:
            return ["get", "--raw", "/apis/metrics.k8s.io/v1beta1/nodes"]
        case .warningEvents:
            return ["get", "events", "--all-namespaces", "--field-selector", "type=Warning", "-o", "json"]
        case let .workload(kind):
            return ["get", kind.kubectlResource, "--all-namespaces", "-o", "json"]
        }
    }

    static func reads(for watchTargets: [WatchTarget]) -> [KubectlRead] {
        var reads: [KubectlRead] = [.nodes, .pods, .nodeMetrics, .warningEvents]
        let targetKinds = Set(watchTargets.compactMap { target -> WorkloadKind? in
            guard case let .workload(_, _, kind) = target, kind.supportsSelectorMetadata else {
                return nil
            }

            return kind
        })

        reads += WorkloadKind.allCases.filter { targetKinds.contains($0) }.map(KubectlRead.workload)
        return reads
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

private struct NodeRecord: Decodable, Equatable, Sendable {
    struct Metadata: Decodable, Equatable, Sendable {
        let name: String
    }

    struct Status: Decodable, Equatable, Sendable {
        let conditions: [Condition]
        let allocatable: [String: String]?
    }

    struct Condition: Decodable, Equatable, Sendable {
        let type: String
        let status: String
        let reason: String?
        let message: String?
    }

    let metadata: Metadata
    let status: Status

    var isReady: Bool {
        readyCondition?.status == "True" && healthIssue.reason == nil && healthIssue.message == nil
    }

    private var readyCondition: Condition? {
        status.conditions.first { $0.type == "Ready" }
    }

    var healthIssue: (reason: String?, message: String?) {
        if let readyCondition, readyCondition.status != "True" {
            return (
                reason: normalizedNodeText(readyCondition.reason) ?? "Ready \(readyCondition.status)",
                message: normalizedNodeText(readyCondition.message)
            )
        }

        if readyCondition == nil {
            return (reason: "Ready status missing", message: nil)
        }

        if let pressureCondition {
            return (
                reason: normalizedNodeText(pressureCondition.reason) ?? pressureCondition.type,
                message: normalizedNodeText(pressureCondition.message)
            )
        }

        return (reason: nil, message: nil)
    }

    private var pressureCondition: Condition? {
        status.conditions.first { condition in
            ["DiskPressure", "MemoryPressure", "PIDPressure", "NetworkUnavailable"].contains(condition.type) &&
                condition.status == "True"
        }
    }
}

private struct NodeMetricsList: Decodable {
    let items: [NodeMetricsRecord]
}

private struct NodeMetricsRecord: Decodable, Equatable, Sendable {
    struct Metadata: Decodable, Equatable, Sendable {
        let name: String
    }

    let metadata: Metadata
    let usage: [String: String]
}

private func normalizedNodeText(_ value: String?) -> String? {
    let text = value?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let text, !text.isEmpty else {
        return nil
    }

    return text
}

private enum ResourceQuantityScale {
    case cpuNanocores
    case memoryBytes

    func multiplier(for suffix: String) -> Double? {
        switch self {
        case .cpuNanocores:
            return cpuMultiplier(for: suffix)
        case .memoryBytes:
            return memoryMultiplier(for: suffix)
        }
    }

    private func cpuMultiplier(for suffix: String) -> Double? {
        switch suffix {
        case "":
            return 1_000_000_000
        case "n":
            return 1
        case "u":
            return 1_000
        case "m":
            return 1_000_000
        case "k":
            return 1_000_000_000_000
        case "M":
            return 1_000_000_000_000_000
        case "G":
            return 1_000_000_000_000_000_000
        default:
            return nil
        }
    }

    private func memoryMultiplier(for suffix: String) -> Double? {
        switch suffix {
        case "":
            return 1
        case "n":
            return 0.000_000_001
        case "u":
            return 0.000_001
        case "m":
            return 0.001
        case "k":
            return 1_000
        case "M":
            return 1_000_000
        case "G":
            return 1_000_000_000
        case "T":
            return 1_000_000_000_000
        case "P":
            return 1_000_000_000_000_000
        case "E":
            return 1_000_000_000_000_000_000
        case "Ki":
            return 1_024
        case "Mi":
            return 1_048_576
        case "Gi":
            return 1_073_741_824
        case "Ti":
            return 1_099_511_627_776
        case "Pi":
            return 1_125_899_906_842_624
        case "Ei":
            return 1_152_921_504_606_846_976
        default:
            return nil
        }
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
        let ownerReferences: [OwnerReference]?
    }

    struct Status: Decodable, Equatable, Sendable {
        let phase: String?
        let reason: String?
        let message: String?
        let conditions: [PodCondition]?
        let containerStatuses: [ContainerStatus]?
    }

    let metadata: Metadata
    let status: Status

    var isRunning: Bool {
        status.phase == "Running"
    }

    var isFailed: Bool {
        status.phase == "Failed"
    }

    var isRestarting: Bool {
        status.containerStatuses?.contains { status in
            (status.restartCount ?? 0) > 0 ||
                status.state?.waiting?.reason == "CrashLoopBackOff"
        } ?? false
    }

    var isNotReady: Bool {
        if status.phase == "Pending" || status.phase == "Unknown" || status.phase == "Failed" {
            return true
        }

        if status.conditions?.contains(where: { condition in
            (condition.type == "Ready" || condition.type == "ContainersReady") && condition.status != "True"
        }) == true {
            return true
        }

        return status.containerStatuses?.contains { $0.ready == false } ?? false
    }

    func matches(target: WatchTarget, workloadSelectors: [WorkloadIdentity: [String: String]]) -> Bool {
        switch target {
        case let .namespace(namespace):
            metadata.namespace == namespace
        case let .workload(namespace, name, kind):
            metadata.namespace == namespace && matchesWorkload(namespace: namespace, name: name, kind: kind, workloadSelectors: workloadSelectors)
        }
    }

    private func matchesWorkload(
        namespace: String,
        name: String,
        kind: WorkloadKind,
        workloadSelectors: [WorkloadIdentity: [String: String]]
    ) -> Bool {
        let identity = WorkloadIdentity(namespace: namespace, name: name, kind: kind)
        if let selector = workloadSelectors[identity], matches(selector: selector) {
            return true
        }

        return matchesWorkload(named: name) || hasOwnerReference(named: name, kind: kind)
    }

    private func matches(selector: [String: String]) -> Bool {
        guard !selector.isEmpty else {
            return false
        }

        return selector.allSatisfy { key, value in
            metadata.labels?[key] == value
        }
    }

    private func matchesWorkload(named name: String) -> Bool {
        metadata.name == name ||
            metadata.labels?["app.kubernetes.io/name"] == name ||
            metadata.labels?["app"] == name
    }

    private func hasOwnerReference(named name: String, kind: WorkloadKind) -> Bool {
        metadata.ownerReferences?.contains { owner in
            owner.kind == kind.displayName && owner.name == name ||
                kind == .cronJob && owner.kind == "Job" && owner.name.hasPrefix("\(name)-")
        } ?? false
    }
}

private struct OwnerReference: Decodable, Equatable, Sendable {
    let kind: String
    let name: String
}

private struct PodCondition: Decodable, Equatable, Sendable {
    let type: String
    let status: String
}

private struct ContainerStatus: Decodable, Equatable, Sendable {
    let ready: Bool?
    let restartCount: Int?
    let state: ContainerState?
    let lastState: ContainerState?
}

private struct ContainerState: Decodable, Equatable, Sendable {
    let waiting: ContainerStateWaiting?
    let terminated: ContainerStateTerminated?
}

private struct ContainerStateWaiting: Decodable, Equatable, Sendable {
    let reason: String?
    let message: String?
}

private struct ContainerStateTerminated: Decodable, Equatable, Sendable {
    let reason: String?
    let message: String?
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

private struct WorkloadIdentity: Equatable, Hashable, Sendable {
    let namespace: String
    let name: String
    let kind: WorkloadKind
}

private struct WorkloadMetadataList: Decodable {
    let items: [WorkloadMetadataRecord]
}

private struct WorkloadMetadataRecord: Decodable, Equatable, Sendable {
    struct Metadata: Decodable, Equatable, Sendable {
        let namespace: String
        let name: String
    }

    struct Spec: Decodable, Equatable, Sendable {
        let selector: Selector?
    }

    struct Selector: Decodable, Equatable, Sendable {
        let matchLabels: [String: String]?
    }

    let metadata: Metadata
    let spec: Spec
    private let kind: WorkloadKind?

    var identity: WorkloadIdentity {
        WorkloadIdentity(namespace: metadata.namespace, name: metadata.name, kind: kind ?? .deployment)
    }

    func with(kind: WorkloadKind) -> WorkloadMetadataRecord {
        WorkloadMetadataRecord(metadata: metadata, spec: spec, kind: kind)
    }

    private init(metadata: Metadata, spec: Spec, kind: WorkloadKind) {
        self.metadata = metadata
        self.spec = spec
        self.kind = kind
    }

    private enum CodingKeys: String, CodingKey {
        case metadata
        case spec
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = try container.decode(Metadata.self, forKey: .metadata)
        self.spec = try container.decode(Spec.self, forKey: .spec)
        self.kind = nil
    }
}
