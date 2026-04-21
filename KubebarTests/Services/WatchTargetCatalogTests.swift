import Foundation
import Testing
@testable import KubebarCore

@Suite("Watch target catalog")
struct WatchTargetCatalogTests {
    @Test("lists namespaces and supported workload candidates")
    func listsNamespacesAndSupportedWorkloadCandidates() throws {
        let runner = RecordingCommandRunner(results: [
            ["--context", "prod", "get", "namespaces", "-o", "json"]: CommandResult(stdout: namespacesJSON, stderr: "", exitCode: 0),
            ["--context", "prod", "get", "deployments", "--all-namespaces", "-o", "json"]: CommandResult(stdout: deploymentJSON, stderr: "", exitCode: 0),
            ["--context", "prod", "get", "statefulsets", "--all-namespaces", "-o", "json"]: CommandResult(stdout: statefulSetJSON, stderr: "", exitCode: 0),
            ["--context", "prod", "get", "daemonsets", "--all-namespaces", "-o", "json"]: CommandResult(stdout: daemonSetJSON, stderr: "", exitCode: 0),
            ["--context", "prod", "get", "cronjobs", "--all-namespaces", "-o", "json"]: CommandResult(stdout: cronJobJSON, stderr: "", exitCode: 0)
        ])
        let catalog = WatchTargetCatalog(runner: runner)

        let candidates = try catalog.listCandidates(contextName: "prod")

        #expect(candidates.namespaces == ["api", "monitoring"])
        #expect(candidates.workloads.map(\.displayTitle) == [
            "Deployment checkout",
            "StatefulSet postgres",
            "CronJob nightly-backup",
            "DaemonSet collector"
        ])
        #expect(candidates.workloads.map(\.target) == [
            .workload(namespace: "api", name: "checkout", kind: .deployment),
            .workload(namespace: "api", name: "postgres", kind: .statefulSet),
            .workload(namespace: "jobs", name: "nightly-backup", kind: .cronJob),
            .workload(namespace: "monitoring", name: "collector", kind: .daemonSet)
        ])
        #expect(runner.recordedArguments.contains(["--context", "prod", "get", "namespaces", "-o", "json"]))
        #expect(!runner.recordedArguments.contains { $0.contains("jobs") })
    }

    @Test("non zero kubectl exit reports stderr")
    func nonZeroKubectlExitReportsStderr() {
        let runner = RecordingCommandRunner(results: [
            ["--context", "prod", "get", "namespaces", "-o", "json"]: CommandResult(stdout: "", stderr: "forbidden", exitCode: 1)
        ])
        let catalog = WatchTargetCatalog(runner: runner)

        #expect(throws: KubectlCommandError.failed("forbidden")) {
            try catalog.listCandidates(contextName: "prod")
        }
    }

    @Test("malformed JSON reports target parse failure")
    func malformedJSONReportsTargetParseFailure() {
        let runner = RecordingCommandRunner(results: [
            ["--context", "prod", "get", "namespaces", "-o", "json"]: CommandResult(stdout: "{", stderr: "", exitCode: 0)
        ])
        let catalog = WatchTargetCatalog(runner: runner)

        #expect(throws: KubectlCommandError.failed("invalid target JSON")) {
            try catalog.listCandidates(contextName: "prod")
        }
    }
}

private final class RecordingCommandRunner: CommandRunning, @unchecked Sendable {
    private let results: [[String]: CommandResult]
    private let lock = NSLock()
    private var storage: [[String]] = []

    init(results: [[String]: CommandResult]) {
        self.results = results
    }

    var recordedArguments: [[String]] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        lock.lock()
        storage.append(request.arguments)
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

private let deploymentJSON = """
{
  "items": [
    {"metadata": {"namespace": "api", "name": "checkout"}}
  ]
}
"""

private let statefulSetJSON = """
{
  "items": [
    {"metadata": {"namespace": "api", "name": "postgres"}}
  ]
}
"""

private let daemonSetJSON = """
{
  "items": [
    {"metadata": {"namespace": "monitoring", "name": "collector"}}
  ]
}
"""

private let cronJobJSON = """
{
  "items": [
    {"metadata": {"namespace": "jobs", "name": "nightly-backup"}}
  ]
}
"""

private let emptyListJSON = """
{
  "items": []
}
"""
