import Foundation
import Testing
@testable import KubebarCore

@Suite("Process command runner")
struct CommandRunnerTests {
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
