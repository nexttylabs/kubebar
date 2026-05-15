import Foundation
import Testing
@testable import KubebarCore

@Suite("k9s handoff launcher")
struct K9sHandoffLauncherTests {
    @Test("launch target is passed as command arguments")
    func launchTargetIsPassedAsCommandArguments() throws {
        let runner = FakeCommandRunner()
        let launcher = K9sHandoffLauncher(runner: runner)

        try launcher.launch(target: K9sHandoffTarget(contextName: "prod", namespace: "api"))

        let request = try #require(runner.request)
        #expect(request.executable == "osascript")
        #expect(request.arguments.count == 6)
        #expect(request.arguments[0] == "-e")
        #expect(request.arguments[2] == "prod")
        #expect(request.arguments[3] == "api")
        #expect(request.arguments[4] == "")
        #expect(request.arguments[5].contains("/usr/bin"))
    }

    @Test("launch avoids opening a separate blank terminal window")
    func launchUsesExistingTerminalWindowIfAvailable() throws {
        let runner = FakeCommandRunner()
        let launcher = K9sHandoffLauncher(runner: runner)

        try launcher.launch(target: K9sHandoffTarget(contextName: "prod", namespace: "api"))

        let request = try #require(runner.request)
        let script = request.arguments[1]
        #expect(!script.contains("activate"))
        #expect(script.contains("if (count of windows) is greater than 0"))
        #expect(script.contains("do script k9sCommand in front window"))
    }

    @Test("launch passes resource command for typed targets")
    func launchPassesResourceCommandForTypedTargets() throws {
        let runner = FakeCommandRunner()
        let launcher = K9sHandoffLauncher(runner: runner)

        try launcher.launch(
            target: K9sHandoffTarget(
                contextName: "prod",
                resource: .workload(namespace: "api", name: "checkout", kind: .deployment)
            )
        )

        let request = try #require(runner.request)
        let script = request.arguments[1]
        #expect(request.arguments[2] == "prod")
        #expect(request.arguments[3] == "api")
        #expect(request.arguments[4] == "deployments")
        #expect(script.contains(" -c "))
    }

    @Test("pod launch opens namespace pods list")
    func podLaunchOpensNamespacePodsList() throws {
        let runner = FakeCommandRunner()
        let launcher = K9sHandoffLauncher(runner: runner)

        try launcher.launch(
            target: K9sHandoffTarget(contextName: "prod", resource: .podList(namespace: "api"))
        )

        let request = try #require(runner.request)
        #expect(request.arguments[2] == "prod")
        #expect(request.arguments[3] == "api")
        #expect(request.arguments[4] == "pods")
    }

    @Test("node launch omits namespace and opens nodes list")
    func nodeLaunchOmitsNamespaceAndOpensNodeResourceView() throws {
        let runner = FakeCommandRunner()
        let launcher = K9sHandoffLauncher(runner: runner)

        try launcher.launch(
            target: K9sHandoffTarget(contextName: "prod", resource: .nodeList)
        )

        let request = try #require(runner.request)
        let script = request.arguments[1]
        #expect(request.arguments[2] == "prod")
        #expect(request.arguments[3] == "")
        #expect(request.arguments[4] == "nodes")
        #expect(script.contains("if namespaceName is not \"\""))
    }

    @Test("launch supports special characters in context and namespace")
    func launchSupportsSpecialCharacters() throws {
        let runner = FakeCommandRunner()
        let launcher = K9sHandoffLauncher(runner: runner)
        let contextName = "prod staging"
        let namespace = "qa/api; rm -rf /"

        try launcher.launch(target: K9sHandoffTarget(contextName: contextName, namespace: namespace))

        let request = try #require(runner.request)
        #expect(request.arguments[2] == contextName)
        #expect(request.arguments[3] == namespace)
    }

    @Test("launcher maps exit failure to handoff failure")
    func launcherMapsFailureToFailureError() throws {
        let runner = FakeCommandRunner(result: CommandResult(stdout: "", stderr: "", exitCode: 1))
        let launcher = K9sHandoffLauncher(runner: runner)

        #expect(throws: K9sHandoffLauncherError.failed) {
            try launcher.launch(target: K9sHandoffTarget(contextName: "prod", namespace: "api"))
        }
    }
}

private final class FakeCommandRunner: CommandRunning, @unchecked Sendable {
    private(set) var request: CommandRequest?
    private let result: CommandResult

    init(result: CommandResult = CommandResult(stdout: "ok", stderr: "", exitCode: 0)) {
        self.result = result
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        self.request = request
        return result
    }
}
