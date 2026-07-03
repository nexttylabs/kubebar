import Foundation
import Testing
@testable import KubebarCore

@Suite("Pod log streaming")
struct PodLogStreamerTests {
    @Test("builds kubectl logs request with context namespace tail follow and kubeconfig")
    func buildsKubectlLogsRequest() {
        let target = PodLogTarget(contextName: "prod", namespace: "api", podName: "checkout-7f9d")
        let request = PodLogStreamRequest(
            target: target,
            config: AppConfig(kubeconfigPaths: ["/tmp/dev.yaml", "/tmp/prod.yaml"])
        )

        #expect(request.command.executable == "kubectl")
        #expect(request.command.arguments == [
            "--context", "prod",
            "logs",
            "--tail=100",
            "-f",
            "-n", "api",
            "checkout-7f9d"
        ])
        #expect(request.command.environmentOverrides == ["KUBECONFIG": "/tmp/dev.yaml:/tmp/prod.yaml"])
    }

    @Test("builds finite diagnostic logs request without follow and with kubeconfig")
    func buildsFiniteDiagnosticLogsRequest() {
        let target = PodLogTarget(contextName: "prod", namespace: "api", podName: "checkout-7f9d")
        let request = PodDiagnosticLogReadRequest(
            target: target,
            config: AppConfig(kubeconfigPaths: ["/tmp/dev.yaml", "/tmp/prod.yaml"])
        )

        #expect(request.command.executable == "kubectl")
        #expect(request.command.arguments == [
            "--context", "prod",
            "logs",
            "--tail=50",
            "-n", "api",
            "checkout-7f9d"
        ])
        #expect(!request.command.arguments.contains("-f"))
        #expect(request.command.environmentOverrides == ["KUBECONFIG": "/tmp/dev.yaml:/tmp/prod.yaml"])
    }

    @Test("finite diagnostic log reader keeps last fifty stdout lines")
    func finiteDiagnosticLogReaderKeepsLastFiftyStdoutLines() async throws {
        let runner = FakeCommandRunner(result: CommandResult(
            stdout: (1...60).map { "line-\($0)" }.joined(separator: "\n"),
            stderr: "",
            exitCode: 0
        ))
        let reader = CommandPodDiagnosticLogReader(runner: runner)
        let request = PodDiagnosticLogReadRequest(
            target: PodLogTarget(contextName: "prod", namespace: "api", podName: "checkout"),
            command: CommandRequest(executable: "/bin/echo", arguments: [])
        )

        let lines = try await reader.readLogs(for: request)

        #expect(lines.count == 50)
        #expect(lines.first == "line-11")
        #expect(lines.last == "line-60")
    }

    @Test("finite diagnostic log reader reports safe stderr on failure")
    func finiteDiagnosticLogReaderReportsSafeStderrOnFailure() async throws {
        let runner = FakeCommandRunner(result: CommandResult(
            stdout: "",
            stderr: "Error from server (BadRequest): container required",
            exitCode: 2
        ))
        let reader = CommandPodDiagnosticLogReader(runner: runner)
        let request = PodDiagnosticLogReadRequest(
            target: PodLogTarget(contextName: "prod", namespace: "api", podName: "checkout"),
            command: CommandRequest(executable: "/bin/echo", arguments: [])
        )

        await #expect(throws: PodDiagnosticLogReadError.commandFailed("container required")) {
            _ = try await reader.readLogs(for: request)
        }
    }

    @Test("stream session separates repeated opens for the same pod target")
    func streamSessionSeparatesRepeatedOpensForSamePodTarget() {
        let target = PodLogTarget(contextName: "prod", namespace: "api", podName: "checkout")
        let first = PodLogStreamSession(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, target: target)
        let second = PodLogStreamSession(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, target: target)

        #expect(first.accepts(id: first.id, target: target))
        #expect(!second.accepts(id: first.id, target: target))
    }

    @Test("bounded log buffer keeps most recent lines and supports search and copy")
    func boundedLogBufferKeepsMostRecentLinesAndSupportsSearchAndCopy() {
        var buffer = PodLogBuffer(maxLineCount: 3)

        buffer.append("first\nsecond error\nthird")
        buffer.append("\nfourth error\n")

        #expect(buffer.lines == ["second error", "third", "fourth error"])
        #expect(buffer.text == "second error\nthird\nfourth error")
        #expect(buffer.matchCount(for: "error") == 2)
        #expect(buffer.matchCount(for: "missing") == 0)
    }

    @Test("bounded log buffer preserves line boundaries across chunks")
    func boundedLogBufferPreservesLineBoundariesAcrossChunks() {
        var buffer = PodLogBuffer(maxLineCount: 4)

        buffer.append("first\nsecond\n")
        buffer.append("third\n")

        #expect(buffer.lines == ["first", "second", "third"])
        #expect(buffer.text == "first\nsecond\nthird")
    }

    @Test("bounded log buffer preserves intentional empty lines")
    func boundedLogBufferPreservesIntentionalEmptyLines() {
        var buffer = PodLogBuffer(maxLineCount: 6)

        buffer.append("first\n\n")
        buffer.append("\nthird\n")

        #expect(buffer.lines == ["first", "", "", "third"])
        #expect(buffer.text == "first\n\n\nthird")
    }

    @Test("stream state summarizes safe failure text")
    func streamStateSummarizesSafeFailureText() {
        let state = PodLogDrawerState.failed("Error from server (BadRequest): a container name must be specified for pod checkout")

        #expect(state.statusText == "Logs unavailable")
        #expect(state.detailText == "a container name must be specified for pod checkout")
    }

    @Test("streaming error localized description preserves command stderr")
    func streamingErrorLocalizedDescriptionPreservesCommandStderr() {
        let error = PodLogStreamingError.commandFailed("container required")

        #expect(error.localizedDescription == "container required")
    }

    @Test("process streamer yields stdout chunks")
    func processStreamerYieldsStdoutChunks() async throws {
        let streamer = ProcessPodLogStreamer()
        let request = PodLogStreamRequest(
            target: PodLogTarget(contextName: "prod", namespace: "api", podName: "checkout"),
            config: AppConfig(),
            kubectlEnvironment: KubectlEnvironment(environmentOverrides: [:])
        )
        let command = CommandRequest(
            executable: "/bin/sh",
            arguments: ["-c", "printf 'first\\nsecond\\n'"],
            timeoutSeconds: 0
        )
        let streamRequest = PodLogStreamRequest(target: request.target, command: command)

        var output = ""
        for try await chunk in streamer.streamLogs(for: streamRequest) {
            output += chunk
        }

        #expect(output == "first\nsecond\n")
    }

    @Test("process streamer reports stderr when command exits nonzero")
    func processStreamerReportsStderrWhenCommandExitsNonzero() async throws {
        let streamer = ProcessPodLogStreamer()
        let target = PodLogTarget(contextName: "prod", namespace: "api", podName: "checkout")
        let streamRequest = PodLogStreamRequest(
            target: target,
            command: CommandRequest(
                executable: "/bin/sh",
                arguments: ["-c", "printf 'container required' >&2; exit 2"],
                timeoutSeconds: 0
            )
        )

        await #expect(throws: PodLogStreamingError.commandFailed("container required")) {
            for try await _ in streamer.streamLogs(for: streamRequest) {}
        }
    }

    @Test("process streamer terminates command when stream task is cancelled")
    func processStreamerTerminatesCommandWhenStreamTaskIsCancelled() async throws {
        let readyMarker = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let marker = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: readyMarker)
            try? FileManager.default.removeItem(at: marker)
        }

        let streamer = ProcessPodLogStreamer()
        let target = PodLogTarget(contextName: "prod", namespace: "api", podName: "checkout")
        let script = """
        trap 'printf terminated > "\(marker.path)"; exit 0' TERM
        printf ready > "\(readyMarker.path)"
        printf started
        while true; do sleep 1; done
        """
        let streamRequest = PodLogStreamRequest(
            target: target,
            command: CommandRequest(
                executable: "/bin/sh",
                arguments: ["-c", script],
                timeoutSeconds: 0
            )
        )

        let task = Task {
            for try await _ in streamer.streamLogs(for: streamRequest) {}
        }

        for _ in 0..<20 {
            if FileManager.default.fileExists(atPath: readyMarker.path) {
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        #expect(FileManager.default.fileExists(atPath: readyMarker.path))
        task.cancel()

        for _ in 0..<20 {
            if FileManager.default.fileExists(atPath: marker.path) {
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        #expect((try? String(contentsOf: marker, encoding: .utf8)) == "terminated")
    }
}

private final class FakeCommandRunner: CommandRunning, @unchecked Sendable {
    private let result: CommandResult

    init(result: CommandResult) {
        self.result = result
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        result
    }
}
