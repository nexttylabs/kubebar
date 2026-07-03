import Foundation

public struct PodDiagnosticLogReadRequest: Equatable, Sendable {
    public let target: PodLogTarget
    public let tailLineCount: Int
    public let command: CommandRequest

    public init(
        target: PodLogTarget,
        config: AppConfig,
        tailLineCount: Int = 50,
        kubectlEnvironment: KubectlEnvironment? = nil
    ) {
        self.target = target
        self.tailLineCount = tailLineCount
        let environment = kubectlEnvironment ?? KubectlEnvironment(config: config)
        self.command = CommandRequest(
            executable: "kubectl",
            arguments: [
                "--context", target.contextName,
                "logs",
                "--tail=\(tailLineCount)",
                "-n", target.namespace,
                target.podName
            ],
            environmentOverrides: environment.environmentOverrides,
            timeoutSeconds: 10
        )
    }

    init(target: PodLogTarget, tailLineCount: Int = 50, command: CommandRequest) {
        self.target = target
        self.tailLineCount = tailLineCount
        self.command = command
    }
}

public enum PodDiagnosticLogReadError: Error, Equatable, Sendable {
    case launchFailed
    case timedOut
    case commandFailed(String)
}

extension PodDiagnosticLogReadError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .launchFailed:
            "kubectl logs failed to launch"
        case .timedOut:
            "kubectl logs timed out"
        case let .commandFailed(message):
            message
        }
    }
}

public protocol PodDiagnosticLogReading: Sendable {
    func readLogs(for request: PodDiagnosticLogReadRequest) async throws -> [String]
}

public struct CommandPodDiagnosticLogReader: PodDiagnosticLogReading, Sendable {
    private let runner: any CommandRunning

    public init(runner: any CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func readLogs(for request: PodDiagnosticLogReadRequest) async throws -> [String] {
        let runner = runner
        return try await Task.detached(priority: .userInitiated) {
            do {
                let result = try runner.run(request.command)
                guard result.exitCode == 0 else {
                    throw PodDiagnosticLogReadError.commandFailed(
                        Self.safeFailureDetail(from: result.stderr)
                    )
                }

                return Self.lastLines(from: result.stdout, limit: request.tailLineCount)
            } catch CommandRunnerError.launchFailed {
                throw PodDiagnosticLogReadError.launchFailed
            } catch CommandRunnerError.timedOut {
                throw PodDiagnosticLogReadError.timedOut
            }
        }.value
    }

    private static func lastLines(from output: String, limit: Int) -> [String] {
        let lines = output
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        let trimmedLines = lines.last == "" ? lines.dropLast() : ArraySlice(lines)
        return Array(trimmedLines.suffix(max(1, limit)))
    }

    private static func safeFailureDetail(from stderr: String) -> String {
        let trimmed = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "kubectl logs failed"
        }

        if let range = trimmed.range(of: "): ") {
            return String(trimmed[range.upperBound...])
        }

        return trimmed
    }
}
