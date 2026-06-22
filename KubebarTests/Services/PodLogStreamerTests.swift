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
        let marker = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: marker)
        }

        let streamer = ProcessPodLogStreamer()
        let target = PodLogTarget(contextName: "prod", namespace: "api", podName: "checkout")
        let script = """
        printf started
        trap 'printf terminated > "\(marker.path)"; exit 0' TERM
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

        try await Task.sleep(nanoseconds: 100_000_000)
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
