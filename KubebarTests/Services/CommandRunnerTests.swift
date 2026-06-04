import Foundation
import Testing
@testable import KubebarCore

@Suite("Process command runner")
struct CommandRunnerTests {
    @Test("launch environment keeps inherited PATH and appends Homebrew paths")
    func launchEnvironmentKeepsInheritedPathAndAppendsHomebrewPaths() {
        let environment = ProcessCommandRunner.launchEnvironment(base: ["PATH": "/usr/bin:/bin"])

        #expect(environment["PATH"] == "/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin:/usr/sbin:/sbin")
    }

    @Test("launch environment removes duplicate search paths")
    func launchEnvironmentRemovesDuplicateSearchPaths() {
        let environment = ProcessCommandRunner.launchEnvironment(
            base: ["PATH": "/opt/homebrew/bin:/usr/bin:/opt/homebrew/bin"]
        )

        #expect(environment["PATH"] == "/opt/homebrew/bin:/usr/bin:/usr/local/bin:/bin:/usr/sbin:/sbin")
    }

    @Test("launch environment preserves colon delimited KUBECONFIG exactly")
    func launchEnvironmentPreservesColonDelimitedKubeconfigExactly() {
        let kubeconfig = "/tmp/dev-config:/tmp/shared-config:/tmp/prod-config"
        let environment = ProcessCommandRunner.launchEnvironment(
            base: [
                "PATH": "/usr/bin:/bin",
                "KUBECONFIG": kubeconfig
            ]
        )

        #expect(environment["KUBECONFIG"] == kubeconfig)
        #expect(environment["PATH"] == "/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin:/usr/sbin:/sbin")
    }

    @Test("launch environment applies explicit overrides after path normalization")
    func launchEnvironmentAppliesExplicitOverridesAfterPathNormalization() {
        let environment = ProcessCommandRunner.launchEnvironment(
            base: ["PATH": "/usr/bin:/bin"],
            environmentOverrides: ["KUBECONFIG": "/tmp/dev:/tmp/prod"]
        )

        #expect(environment["PATH"] == "/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin:/usr/sbin:/sbin")
        #expect(environment["KUBECONFIG"] == "/tmp/dev:/tmp/prod")
    }

    @Test("kubectl environment uses inherited kubeconfig when present")
    func kubectlEnvironmentUsesInheritedKubeconfigWhenPresent() {
        let environment = KubectlEnvironment(
            baseEnvironment: ["KUBECONFIG": "/tmp/dev:/tmp/prod"],
            shellLookup: FakeShellEnvironmentLookup(value: "/tmp/shell")
        )

        #expect(environment.environmentOverrides == ["KUBECONFIG": "/tmp/dev:/tmp/prod"])
    }

    @Test("kubectl environment uses explicit kubeconfig paths when configured")
    func kubectlEnvironmentUsesExplicitKubeconfigPathsWhenConfigured() {
        let environment = KubectlEnvironment(
            config: AppConfig(
                kubeconfigPaths: ["/tmp/dev.yaml", "/tmp/prod.yaml"]
            ),
            baseEnvironment: ["KUBECONFIG": "/tmp/ignored"],
            shellLookup: FakeShellEnvironmentLookup(value: "/tmp/shell")
        )

        #expect(environment.environmentOverrides == ["KUBECONFIG": "/tmp/dev.yaml:/tmp/prod.yaml"])
    }

    @Test("kubectl environment falls back to automatic detection when explicit path list is empty")
    func kubectlEnvironmentFallsBackToAutomaticDetectionWhenExplicitPathListIsEmpty() {
        let environment = KubectlEnvironment(
            config: AppConfig(kubeconfigPaths: []),
            baseEnvironment: ["KUBECONFIG": "/tmp/dev:/tmp/prod"],
            shellLookup: FakeShellEnvironmentLookup(value: "/tmp/shell")
        )

        #expect(environment.environmentOverrides == ["KUBECONFIG": "/tmp/dev:/tmp/prod"])
    }

    @Test("kubectl environment ignores empty explicit kubeconfig paths")
    func kubectlEnvironmentIgnoresEmptyExplicitKubeconfigPaths() {
        let environment = KubectlEnvironment(
            config: AppConfig(kubeconfigPaths: ["  ", "/tmp/prod.yaml", ""]),
            baseEnvironment: [:],
            shellLookup: FakeShellEnvironmentLookup(value: nil)
        )

        #expect(environment.environmentOverrides == ["KUBECONFIG": "/tmp/prod.yaml"])
    }

    @Test("kubectl environment falls back to login shell kubeconfig when inherited environment is missing")
    func kubectlEnvironmentFallsBackToLoginShellKubeconfigWhenInheritedEnvironmentIsMissing() {
        let environment = KubectlEnvironment(
            baseEnvironment: [:],
            shellLookup: FakeShellEnvironmentLookup(value: "/tmp/dev:/tmp/prod")
        )

        #expect(environment.environmentOverrides == ["KUBECONFIG": "/tmp/dev:/tmp/prod"])
    }

    @Test("kubectl environment ignores empty inherited and shell kubeconfig values")
    func kubectlEnvironmentIgnoresEmptyInheritedAndShellKubeconfigValues() {
        let environment = KubectlEnvironment(
            baseEnvironment: ["KUBECONFIG": "   "],
            shellLookup: FakeShellEnvironmentLookup(value: nil)
        )

        #expect(environment.environmentOverrides.isEmpty)
    }

    @Test("login shell lookup extracts marked kubeconfig from noisy output")
    func loginShellLookupExtractsMarkedKubeconfigFromNoisyOutput() {
        let runner = FakeShellRunner(
            result: CommandResult(
                stdout: "welcome\n__KUBEBAR_ENV__KUBECONFIG__=/tmp/dev:/tmp/prod\n",
                stderr: "",
                exitCode: 0
            )
        )
        let lookup = LoginShellEnvironmentLookup(runner: runner, shellPath: "/bin/zsh")

        #expect(lookup.value(for: "KUBECONFIG") == "/tmp/dev:/tmp/prod")
        #expect(runner.lastRequest?.executable == "/bin/zsh")
    }

    @Test("runs executable discovered through additional search path")
    func runsExecutableDiscoveredThroughAdditionalSearchPath() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let executable = directory.appendingPathComponent("kubebar-command-runner-path-test")
        try """
        #!/bin/sh
        printf additional-path
        """.write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let runner = ProcessCommandRunner(additionalExecutableSearchPaths: [directory.path])

        let result = try runner.run(
            CommandRequest(executable: executable.lastPathComponent, arguments: [], timeoutSeconds: 5)
        )

        #expect(result.exitCode == 0)
        #expect(result.stdout == "additional-path")
    }

    @Test("drains large stdout and stderr while command is running")
    func drainsLargeStdoutAndStderrWhileCommandIsRunning() throws {
        let runner = ProcessCommandRunner()
        let byteCount = 200_000

        let result = try runner.run(
            CommandRequest(
                executable: "/bin/sh",
                arguments: [
                    "-c",
                    "yes stdout | head -c \(byteCount); (yes stderr | head -c \(byteCount)) >&2"
                ],
                timeoutSeconds: 5
            )
        )

        #expect(result.exitCode == 0)
        #expect(result.stdout.utf8.count == byteCount)
        #expect(result.stderr.utf8.count == byteCount)
    }

    @Test("terminates process when task is cancelled")
    func terminatesProcessWhenTaskIsCancelled() async throws {
        let runner = ProcessCommandRunner()
        let task = Task {
            try runner.run(
                CommandRequest(
                    executable: "/bin/sh",
                    arguments: ["-c", "sleep 5"],
                    timeoutSeconds: 10
                )
            )
        }

        try await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}

private struct FakeShellEnvironmentLookup: ShellEnvironmentLookup {
    let value: String?

    func value(for variable: String) -> String? {
        value
    }
}

private final class FakeShellRunner: CommandRunning, @unchecked Sendable {
    let result: CommandResult
    private(set) var lastRequest: CommandRequest?

    init(result: CommandResult) {
        self.result = result
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        lastRequest = request
        return result
    }
}
