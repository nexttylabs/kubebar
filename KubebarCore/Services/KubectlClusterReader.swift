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
        let nodes = try decodeNodes(try runKubectl(contextName: contextName, arguments: ["get", "nodes", "-o", "json"]))
        let pods = try decodePods(try runKubectl(contextName: contextName, arguments: ["get", "pods", "--all-namespaces", "-o", "json"]))
        let warningEventCount = try decodeEventCount(
            try runKubectl(
                contextName: contextName,
                arguments: ["get", "events", "--all-namespaces", "--field-selector", "type=Warning", "-o", "json"]
            )
        )

        return ClusterSnapshot(
            contextName: contextName,
            nodeSummary: nodes,
            podSummary: PodSummary(running: pods.filter(\.isRunning).count, total: pods.count),
            warningEventCount: warningEventCount,
            trackedItems: watchTargets.map { target in trackedStatus(for: target, pods: pods) },
            capturedAt: now
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
