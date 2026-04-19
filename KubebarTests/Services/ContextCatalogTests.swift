import Testing
@testable import KubebarCore

@Suite("Context catalog")
struct ContextCatalogTests {
    @Test("lists kubectl contexts from command output")
    func listsKubectlContextsFromCommandOutput() throws {
        let runner = FakeCommandRunner(result: CommandResult(stdout: "prod\nstaging\n\n", stderr: "", exitCode: 0))
        let catalog = ContextCatalog(runner: runner)

        #expect(try catalog.listContexts() == ["prod", "staging"])
        #expect(runner.lastRequest?.executable == "kubectl")
        #expect(runner.lastRequest?.arguments == ["config", "get-contexts", "-o", "name"])
    }

    @Test("empty context output is recoverable")
    func emptyContextOutputIsRecoverable() throws {
        let runner = FakeCommandRunner(result: CommandResult(stdout: "", stderr: "", exitCode: 0))
        let catalog = ContextCatalog(runner: runner)

        #expect(try catalog.listContexts().isEmpty)
    }

    @Test("non-zero kubectl exit reports stderr")
    func nonZeroKubectlExitReportsStderr() {
        let runner = FakeCommandRunner(result: CommandResult(stdout: "", stderr: "no kubeconfig", exitCode: 1))
        let catalog = ContextCatalog(runner: runner)

        #expect(throws: KubectlCommandError.failed("no kubeconfig")) {
            try catalog.listContexts()
        }
    }
}

private final class FakeCommandRunner: CommandRunning, @unchecked Sendable {
    private let result: CommandResult
    private(set) var lastRequest: CommandRequest?

    init(result: CommandResult) {
        self.result = result
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        lastRequest = request
        return result
    }
}
