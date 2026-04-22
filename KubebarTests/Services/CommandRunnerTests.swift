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
