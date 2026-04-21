import Foundation

public protocol WatchTargetCataloging: Sendable {
    func listCandidates(contextName: String) throws -> WatchlistCandidates
}

public struct WatchTargetCatalog: WatchTargetCataloging, Sendable {
    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func listCandidates(contextName: String) throws -> WatchlistCandidates {
        let namespaces = try decodeNamespaces(runKubectl(contextName: contextName, arguments: ["get", "namespaces", "-o", "json"]))
        let workloads = try WorkloadKind.allCases.flatMap { kind in
            try decodeWorkloads(
                runKubectl(
                    contextName: contextName,
                    arguments: ["get", kind.kubectlResource, "--all-namespaces", "-o", "json"]
                ),
                kind: kind
            )
        }

        return WatchlistCandidates(
            namespaces: namespaces.sorted(),
            workloads: workloads.sorted { left, right in
                if left.namespace != right.namespace {
                    return left.namespace < right.namespace
                }

                if left.kind?.displayName != right.kind?.displayName {
                    return (left.kind?.displayName ?? "") < (right.kind?.displayName ?? "")
                }

                return left.name < right.name
            }
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

    private func decodeNamespaces(_ json: String) throws -> [String] {
        do {
            return try JSONDecoder()
                .decode(NamespaceList.self, from: Data(json.utf8))
                .items
                .map(\.metadata.name)
                .filter { !$0.isEmpty }
        } catch {
            throw KubectlCommandError.failed("invalid target JSON")
        }
    }

    private func decodeWorkloads(_ json: String, kind: WorkloadKind) throws -> [WatchlistCandidate] {
        do {
            return try JSONDecoder()
                .decode(WorkloadList.self, from: Data(json.utf8))
                .items
                .map { item in
                    WatchlistCandidate.workload(
                        namespace: item.metadata.namespace,
                        name: item.metadata.name,
                        kind: kind
                    )
                }
                .filter { !$0.namespace.isEmpty && !$0.name.isEmpty }
        } catch {
            throw KubectlCommandError.failed("invalid target JSON")
        }
    }
}

private struct NamespaceList: Decodable {
    let items: [NamespaceRecord]
}

private struct NamespaceRecord: Decodable {
    struct Metadata: Decodable {
        let name: String
    }

    let metadata: Metadata
}

private struct WorkloadList: Decodable {
    let items: [WorkloadRecord]
}

private struct WorkloadRecord: Decodable {
    struct Metadata: Decodable {
        let namespace: String
        let name: String
    }

    let metadata: Metadata
}
