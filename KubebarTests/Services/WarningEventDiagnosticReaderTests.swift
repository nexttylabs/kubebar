import Foundation
import Testing
@testable import KubebarCore

@Suite("Warning Event diagnostic reader")
struct WarningEventDiagnosticReaderTests {
    @Test("builds fresh kubectl warning events request with context and kubeconfig")
    func buildsFreshWarningEventsRequest() {
        let target = WarningEventDiagnosticTarget(
            contextName: "prod",
            namespace: "api",
            objectKind: "Pod",
            objectName: "checkout-7f9d",
            reason: "BackOff"
        )
        let request = WarningEventDiagnosticReadRequest(
            target: target,
            config: AppConfig(kubeconfigPaths: ["/tmp/dev.yaml", "/tmp/prod.yaml"])
        )

        #expect(request.command.executable == "kubectl")
        #expect(request.command.arguments == [
            "--context", "prod",
            "get", "events",
            "--all-namespaces",
            "--field-selector", "type=Warning",
            "-o", "json"
        ])
        #expect(request.command.environmentOverrides == ["KUBECONFIG": "/tmp/dev.yaml:/tmp/prod.yaml"])
    }

    @Test("filters by exact event group key sorts newest first and caps at five")
    func filtersByExactKeySortsNewestAndCapsAtFive() async throws {
        let target = WarningEventDiagnosticTarget(
            contextName: "prod",
            namespace: "api",
            objectKind: "Pod",
            objectName: "checkout-7f9d",
            reason: "BackOff"
        )
        let runner = FakeWarningEventCommandRunner(result: CommandResult(
            stdout: Self.warningEventsJSON,
            stderr: "",
            exitCode: 0
        ))
        let reader = CommandWarningEventDiagnosticReader(runner: runner)
        let request = WarningEventDiagnosticReadRequest(
            target: target,
            command: CommandRequest(executable: "kubectl", arguments: [])
        )

        let events = try await reader.readEvents(for: request)

        #expect(events.count == 5)
        #expect(events.map(\.message) == ["match-7 token=[REDACTED-LATER]", "match-6", "match-5", "match-4", "match-3"])
        #expect(events.allSatisfy { event in
            event.namespace == "api" &&
                event.objectKind == "Pod" &&
                event.objectName == "checkout-7f9d" &&
                event.reason == "BackOff"
        })
        #expect(!events.contains { $0.objectName == "checkout-other" })
        #expect(!events.contains { $0.reason == "FailedScheduling" })
    }

    @Test("reports safe stderr on kubectl failure")
    func reportsSafeStderrOnFailure() async throws {
        let target = WarningEventDiagnosticTarget(
            contextName: "prod",
            namespace: "api",
            objectKind: "Pod",
            objectName: "checkout-7f9d",
            reason: "BackOff"
        )
        let runner = FakeWarningEventCommandRunner(result: CommandResult(
            stdout: "",
            stderr: "Error from server (Forbidden): token secret denied",
            exitCode: 1
        ))
        let reader = CommandWarningEventDiagnosticReader(runner: runner)
        let request = WarningEventDiagnosticReadRequest(
            target: target,
            command: CommandRequest(executable: "kubectl", arguments: [])
        )

        await #expect(throws: WarningEventDiagnosticReadError.commandFailed("kubectl events failed")) {
            _ = try await reader.readEvents(for: request)
        }
    }

    private static let warningEventsJSON = """
    {
      "items": [
        {"reason":"BackOff","message":"match-1","involvedObject":{"kind":"Pod","namespace":"api","name":"checkout-7f9d"},"lastTimestamp":"2026-07-02T00:01:00Z","type":"Warning","count":1},
        {"reason":"BackOff","message":"match-2","involvedObject":{"kind":"Pod","namespace":"api","name":"checkout-7f9d"},"lastTimestamp":"2026-07-02T00:02:00Z","type":"Warning","count":1},
        {"reason":"BackOff","message":"match-3","involvedObject":{"kind":"Pod","namespace":"api","name":"checkout-7f9d"},"lastTimestamp":"2026-07-02T00:03:00Z","type":"Warning","count":1},
        {"reason":"BackOff","message":"match-4","involvedObject":{"kind":"Pod","namespace":"api","name":"checkout-7f9d"},"lastTimestamp":"2026-07-02T00:04:00Z","type":"Warning","count":1},
        {"reason":"BackOff","message":"match-5","involvedObject":{"kind":"Pod","namespace":"api","name":"checkout-7f9d"},"lastTimestamp":"2026-07-02T00:05:00Z","type":"Warning","count":1},
        {"reason":"BackOff","message":"match-6","involvedObject":{"kind":"Pod","namespace":"api","name":"checkout-7f9d"},"lastTimestamp":"2026-07-02T00:06:00Z","type":"Warning","count":1},
        {"reason":"BackOff","message":"match-7 token=[REDACTED-LATER]","involvedObject":{"kind":"Pod","namespace":"api","name":"checkout-7f9d"},"lastTimestamp":"2026-07-02T00:07:00Z","type":"Warning","count":1},
        {"reason":"BackOff","message":"wrong pod","involvedObject":{"kind":"Pod","namespace":"api","name":"checkout-other"},"lastTimestamp":"2026-07-02T00:08:00Z","type":"Warning","count":1},
        {"reason":"FailedScheduling","message":"wrong reason","involvedObject":{"kind":"Pod","namespace":"api","name":"checkout-7f9d"},"lastTimestamp":"2026-07-02T00:09:00Z","type":"Warning","count":1}
      ]
    }
    """
}

private final class FakeWarningEventCommandRunner: CommandRunning, @unchecked Sendable {
    private let result: CommandResult

    init(result: CommandResult) {
        self.result = result
    }

    func run(_ request: CommandRequest) throws -> CommandResult {
        result
    }
}
