import Foundation
import Testing
@testable import KubebarCore

@Suite("k9s handoff launcher")
struct K9sHandoffLauncherTests {
    @Test("launch target is passed as command arguments")
    func launchTargetIsPassedAsCommandArguments() throws {
        let runner = FakeCommandRunner()
        let launcher = K9sHandoffLauncher(runner: runner)

        try launcher.launch(contextName: "prod", namespace: "api")

        let request = try #require(runner.request)
        #expect(request.executable == "osascript")
        #expect(request.arguments.count == 5)
        #expect(request.arguments[0] == "-e")
        #expect(request.arguments[2] == "prod")
        #expect(request.arguments[3] == "api")
        #expect(request.arguments[4].contains("/usr/bin"))
    }

    @Test("launch supports special characters in context and namespace")
    func launchSupportsSpecialCharacters() throws {
        let runner = FakeCommandRunner()
        let launcher = K9sHandoffLauncher(runner: runner)
        let contextName = "prod staging"
        let namespace = "qa/api; rm -rf /"

        try launcher.launch(contextName: contextName, namespace: namespace)

        let request = try #require(runner.request)
        #expect(request.arguments[2] == contextName)
        #expect(request.arguments[3] == namespace)
    }

    @Test("launcher maps exit failure to handoff failure")
    func launcherMapsFailureToFailureError() throws {
        let runner = FakeCommandRunner(result: CommandResult(stdout: "", stderr: "", exitCode: 1))
        let launcher = K9sHandoffLauncher(runner: runner)

        #expect(throws: K9sHandoffLauncherError.failed) {
            try launcher.launch(contextName: "prod", namespace: "api")
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
