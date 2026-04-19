import Foundation
import Testing
@testable import KubebarCore

@Suite("Kubectl cluster reader")
struct KubectlClusterReaderTests {
    @Test("builds a cluster snapshot from kubectl JSON")
    func buildsClusterSnapshotFromKubectlJSON() throws {
        let runner = FakeMultiCommandRunner(results: [
            ["--context", "prod", "get", "nodes", "-o", "json"]: CommandResult(stdout: nodesJSON, stderr: "", exitCode: 0),
            ["--context", "prod", "get", "pods", "--all-namespaces", "-o", "json"]: CommandResult(stdout: podsJSON, stderr: "", exitCode: 0),
            ["--context", "prod", "get", "events", "--all-namespaces", "--field-selector", "type=Warning", "-o", "json"]: CommandResult(stdout: warningEventsJSON, stderr: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        let snapshot = try reader.readSnapshot(
            contextName: "prod",
            watchTargets: [.workload(namespace: "api", name: "checkout")],
            now: Date(timeIntervalSince1970: 100)
        )

        #expect(snapshot.contextName == "prod")
        #expect(snapshot.nodeSummary == NodeSummary(ready: 1, total: 2))
        #expect(snapshot.podSummary == PodSummary(running: 1, total: 3))
        #expect(snapshot.warningEventCount == 1)
        #expect(snapshot.trackedItems.first?.state == .bad)
        #expect(snapshot.trackedItems.first?.reason == "1/2 pods running")
    }

    @Test("kubectl command failure reports stderr")
    func kubectlCommandFailureReportsStderr() {
        let runner = FakeMultiCommandRunner(results: [
            ["--context", "prod", "get", "nodes", "-o", "json"]: CommandResult(stdout: "", stderr: "cluster unreachable", exitCode: 1)
        ])
        let reader = KubectlClusterReader(runner: runner)

        #expect(throws: KubectlCommandError.failed("cluster unreachable")) {
            try reader.readSnapshot(contextName: "prod", watchTargets: [], now: Date())
        }
    }

    @Test("reads independent kubectl resources concurrently")
    func readsIndependentKubectlResourcesConcurrently() throws {
        let runner = SlowRecordingCommandRunner(results: [
            ["--context", "prod", "get", "nodes", "-o", "json"]: CommandResult(stdout: nodesJSON, stderr: "", exitCode: 0),
            ["--context", "prod", "get", "pods", "--all-namespaces", "-o", "json"]: CommandResult(stdout: podsJSON, stderr: "", exitCode: 0),
            ["--context", "prod", "get", "events", "--all-namespaces", "--field-selector", "type=Warning", "-o", "json"]: CommandResult(stdout: warningEventsJSON, stderr: "", exitCode: 0)
        ])
        let reader = KubectlClusterReader(runner: runner)

        _ = try reader.readSnapshot(
            contextName: "prod",
            watchTargets: [.workload(namespace: "api", name: "checkout")],
            now: Date(timeIntervalSince1970: 100)
        )

        #expect(runner.maximumConcurrentRequests > 1)
    }
}

private final class FakeMultiCommandRunner: CommandRunning, @unchecked Sendable {
    private let results: [[String]: CommandResult]

    init(results: [[String]: CommandResult]) {
        self.results = results
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        results[request.arguments] ?? CommandResult(stdout: "", stderr: "unexpected command", exitCode: 1)
    }
}

private final class SlowRecordingCommandRunner: CommandRunning, @unchecked Sendable {
    private let results: [[String]: CommandResult]
    private let lock = NSLock()
    private var activeRequests = 0
    private var observedMaximumConcurrentRequests = 0

    init(results: [[String]: CommandResult]) {
        self.results = results
    }

    var maximumConcurrentRequests: Int {
        lock.lock()
        defer { lock.unlock() }
        return observedMaximumConcurrentRequests
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        incrementActiveRequests()
        Thread.sleep(forTimeInterval: 0.05)
        decrementActiveRequests()

        return results[request.arguments] ?? CommandResult(stdout: "", stderr: "unexpected command", exitCode: 1)
    }

    private func incrementActiveRequests() {
        lock.lock()
        activeRequests += 1
        observedMaximumConcurrentRequests = max(observedMaximumConcurrentRequests, activeRequests)
        lock.unlock()
    }

    private func decrementActiveRequests() {
        lock.lock()
        activeRequests -= 1
        lock.unlock()
    }
}

private let nodesJSON = """
{
  "items": [
    {"status": {"conditions": [{"type": "Ready", "status": "True"}]}},
    {"status": {"conditions": [{"type": "Ready", "status": "False"}]}}
  ]
}
"""

private let podsJSON = """
{
  "items": [
    {"metadata": {"namespace": "api", "name": "checkout-7f9d", "labels": {"app.kubernetes.io/name": "checkout"}}, "status": {"phase": "Running"}},
    {"metadata": {"namespace": "api", "name": "checkout-8a1b", "labels": {"app.kubernetes.io/name": "checkout"}}, "status": {"phase": "Pending"}},
    {"metadata": {"namespace": "api", "name": "checkout-worker-1", "labels": {"app.kubernetes.io/name": "checkout-worker"}}, "status": {"phase": "Pending"}}
  ]
}
"""

private let warningEventsJSON = """
{
  "items": [
    {"metadata": {"namespace": "api", "name": "checkout-warning"}}
  ]
}
"""
