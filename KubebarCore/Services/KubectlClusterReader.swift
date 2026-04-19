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
        let rawSnapshot = try readRawSnapshot(contextName: contextName)
        let nodes = try decodeNodes(rawSnapshot.nodes)
        let pods = try decodePods(rawSnapshot.pods)
        let warningEventCount = try decodeEventCount(rawSnapshot.warningEvents)

        return ClusterSnapshot(
            contextName: contextName,
            nodeSummary: nodes,
            podSummary: PodSummary(running: pods.filter(\.isRunning).count, total: pods.count),
            warningEventCount: warningEventCount,
            trackedItems: watchTargets.map { target in trackedStatus(for: target, pods: pods) },
            capturedAt: now
        )
    }

    private func readRawSnapshot(contextName: String) throws -> RawKubectlSnapshot {
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

        let outputs = try Dictionary(
            uniqueKeysWithValues: KubectlRead.allCases.map { read in
                guard let result = results.result(for: read) else {
                    throw KubectlCommandError.failed("kubectl failed")
                }

                return (read, try result.get())
            }
        )

        return RawKubectlSnapshot(
            nodes: outputs[.nodes] ?? "",
            pods: outputs[.pods] ?? "",
            warningEvents: outputs[.warningEvents] ?? ""
        )
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
            let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw KubectlCommandError.failed(message.isEmpty ? "kubectl failed" : message)
        }

        return result.stdout
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

    private func decodeEventCount(_ json: String) throws -> Int {
        do {
            return try JSONDecoder().decode(EventList.self, from: Data(json.utf8)).items.count
        } catch {
            throw KubectlCommandError.failed("invalid event JSON")
        }
    }

    private func trackedStatus(for target: WatchTarget, pods: [PodRecord]) -> TrackedItemStatus {
        let matchingPods = pods.filter { pod in
            switch target {
            case let .namespace(namespace):
                pod.metadata.namespace == namespace
            case let .workload(namespace, name):
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
    let nodes: String
    let pods: String
    let warningEvents: String
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

private struct PodRecord: Decodable {
    struct Metadata: Decodable {
        let namespace: String
        let name: String
        let labels: [String: String]?
    }

    struct Status: Decodable {
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
    struct EventRecord: Decodable {}

    let items: [EventRecord]
}
