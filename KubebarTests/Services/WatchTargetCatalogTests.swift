import Foundation
import Testing
@testable import KubebarCore

@Suite("Watch target catalog")
struct WatchTargetCatalogTests {
    @Test("lists namespace candidates only")
    func listsNamespaceCandidatesOnly() async throws {
        let runner = RecordingCommandRunner(results: [
            ["--context", "prod", "get", "namespaces", "-o", "json"]: CommandResult(stdout: namespacesJSON, stderr: "", exitCode: 0)
        ])
        let catalog = WatchTargetCatalog(
            runner: runner,
            kubectlEnvironment: KubectlEnvironment(
                environmentOverrides: ["KUBECONFIG": "/tmp/dev:/tmp/prod"]
            )
        )

        let candidates = try await catalog.listCandidates(contextName: "prod")

        #expect(candidates.namespaces == ["api", "monitoring"])
        #expect(candidates.workloads.isEmpty)
        #expect(runner.recordedArguments == [["--context", "prod", "get", "namespaces", "-o", "json"]])
        #expect(runner.recordedEnvironmentOverrides == [["KUBECONFIG": "/tmp/dev:/tmp/prod"]])
    }

    @Test("non zero kubectl exit reports stderr")
    func nonZeroKubectlExitReportsStderr() async {
        let runner = RecordingCommandRunner(results: [
            ["--context", "prod", "get", "namespaces", "-o", "json"]: CommandResult(stdout: "", stderr: "forbidden", exitCode: 1)
        ])
        let catalog = WatchTargetCatalog(runner: runner)

        await #expect(throws: KubectlCommandError.failed("forbidden")) {
            try await catalog.listCandidates(contextName: "prod")
        }
    }

    @Test("malformed JSON reports target parse failure")
    func malformedJSONReportsTargetParseFailure() async {
        let runner = RecordingCommandRunner(results: [
            ["--context", "prod", "get", "namespaces", "-o", "json"]: CommandResult(stdout: "{", stderr: "", exitCode: 0)
        ])
        let catalog = WatchTargetCatalog(runner: runner)

        await #expect(throws: KubectlCommandError.failed("invalid target JSON")) {
            try await catalog.listCandidates(contextName: "prod")
        }
    }

    @Test("watch target catalog derives explicit kubeconfig paths from config")
    func watchTargetCatalogDerivesExplicitKubeconfigPathsFromConfig() async throws {
        let runner = RecordingCommandRunner(results: [
            ["--context", "prod", "get", "namespaces", "-o", "json"]: CommandResult(stdout: namespacesJSON, stderr: "", exitCode: 0)
        ])
        let catalog = WatchTargetCatalog(runner: runner)

        _ = try await catalog.listCandidates(
            config: AppConfig(kubeconfigPaths: ["/tmp/dev.yaml", "/tmp/prod.yaml"]),
            contextName: "prod"
        )

        #expect(runner.recordedEnvironmentOverrides == [["KUBECONFIG": "/tmp/dev.yaml:/tmp/prod.yaml"]])
    }
}

private final class RecordingCommandRunner: CommandRunning, @unchecked Sendable {
    private let results: [[String]: CommandResult]
    private let lock = NSLock()
    private var storage: [[String]] = []
    private var environmentStorage: [[String: String]] = []

    init(results: [[String]: CommandResult]) {
        self.results = results
    }

    var recordedArguments: [[String]] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    var recordedEnvironmentOverrides: [[String: String]] {
        lock.lock()
        defer { lock.unlock() }
        return environmentStorage
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        lock.lock()
        storage.append(request.arguments)
        environmentStorage.append(request.environmentOverrides)
        lock.unlock()

        return results[request.arguments] ?? CommandResult(stdout: emptyListJSON, stderr: "", exitCode: 0)
    }
}

private let namespacesJSON = """
{
  "items": [
    {"metadata": {"name": "monitoring"}},
    {"metadata": {"name": "api"}}
  ]
}
"""

private let emptyListJSON = """
{
  "items": []
}
"""
