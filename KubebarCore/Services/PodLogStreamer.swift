import Foundation

public struct PodLogTarget: Equatable, Sendable, Identifiable {
    public let contextName: String
    public let namespace: String
    public let podName: String

    public var id: String {
        "\(contextName)/\(namespace)/\(podName)"
    }

    public init(contextName: String, namespace: String, podName: String) {
        self.contextName = contextName
        self.namespace = namespace
        self.podName = podName
    }

    public var displayName: String {
        "\(namespace)/\(podName)"
    }
}

public struct PodLogStreamSession: Equatable, Sendable {
    public let id: UUID
    public let target: PodLogTarget

    public init(id: UUID = UUID(), target: PodLogTarget) {
        self.id = id
        self.target = target
    }

    public func accepts(id candidateID: UUID, target candidateTarget: PodLogTarget) -> Bool {
        id == candidateID && target == candidateTarget
    }
}

public struct PodLogStreamRequest: Equatable, Sendable {
    public let target: PodLogTarget
    public let tailLineCount: Int
    public let command: CommandRequest

    public init(
        target: PodLogTarget,
        config: AppConfig,
        tailLineCount: Int = 100,
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
                "-f",
                "-n", target.namespace,
                target.podName
            ],
            environmentOverrides: environment.environmentOverrides,
            timeoutSeconds: 0
        )
    }

    init(target: PodLogTarget, tailLineCount: Int = 100, command: CommandRequest) {
        self.target = target
        self.tailLineCount = tailLineCount
        self.command = command
    }
}

public struct PodLogBuffer: Equatable, Sendable {
    public private(set) var lines: [String]
    public let maxLineCount: Int
    private var hasOpenLine: Bool

    public init(lines: [String] = [], maxLineCount: Int = 1_000) {
        self.maxLineCount = max(1, maxLineCount)
        self.lines = Array(lines.suffix(self.maxLineCount))
        self.hasOpenLine = !self.lines.isEmpty
    }

    public var text: String {
        lines.joined(separator: "\n")
    }

    public mutating func append(_ chunk: String) {
        let nextLines = chunk
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        guard !nextLines.isEmpty else {
            return
        }

        if lines.isEmpty || !hasOpenLine {
            lines.append(contentsOf: nextLines)
        } else if chunk.hasPrefix("\n") {
            lines.append(contentsOf: nextLines.dropFirst())
        } else {
            lines[lines.count - 1] += nextLines[0]
            lines.append(contentsOf: nextLines.dropFirst())
        }

        hasOpenLine = !chunk.hasSuffix("\n")

        if !hasOpenLine, lines.last == "" {
            lines.removeLast()
        }

        if lines.count > maxLineCount {
            lines = Array(lines.suffix(maxLineCount))
        }
    }

    public func matchCount(for query: String) -> Int {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return 0
        }

        return lines.reduce(0) { count, line in
            count + line.localizedCaseInsensitiveContains(normalizedQuery).asInt
        }
    }
}

public enum PodLogDrawerState: Equatable, Sendable {
    case idle
    case loading
    case live
    case ended
    case empty
    case failed(String)
    case cancelled

    public var statusText: String {
        switch self {
        case .idle:
            "Logs idle"
        case .loading:
            "Loading logs..."
        case .live:
            "Live logs"
        case .ended:
            "Log stream ended"
        case .empty:
            "No log output"
        case .failed:
            "Logs unavailable"
        case .cancelled:
            "Log stream stopped"
        }
    }

    public var detailText: String? {
        switch self {
        case let .failed(message):
            Self.safeFailureDetail(from: message)
        default:
            nil
        }
    }

    private static func safeFailureDetail(from message: String) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "kubectl logs failed"
        }

        if let range = trimmed.range(of: "): ") {
            return String(trimmed[range.upperBound...])
        }

        return trimmed
    }
}

public enum PodLogStreamingError: Error, Equatable, Sendable {
    case launchFailed
    case commandFailed(String)
}

extension PodLogStreamingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .launchFailed:
            "kubectl logs failed to launch"
        case let .commandFailed(message):
            message
        }
    }
}

public protocol PodLogStreaming: Sendable {
    func streamLogs(for request: PodLogStreamRequest) -> AsyncThrowingStream<String, Error>
}

public final class ProcessPodLogStreamer: PodLogStreaming, @unchecked Sendable {
    private let additionalExecutableSearchPaths: [String]

    public convenience init() {
        self.init(additionalExecutableSearchPaths: ProcessCommandRunner.defaultExecutableSearchPaths)
    }

    init(additionalExecutableSearchPaths: [String]) {
        self.additionalExecutableSearchPaths = additionalExecutableSearchPaths
    }

    public func streamLogs(for request: PodLogStreamRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let processBox = PodLogProcessBox()
            let stdout = Pipe()
            let stderr = Pipe()
            let process = Process()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [request.command.executable] + request.command.arguments
            process.environment = ProcessCommandRunner.launchEnvironment(
                base: ProcessInfo.processInfo.environment,
                additionalExecutableSearchPaths: additionalExecutableSearchPaths,
                environmentOverrides: request.command.environmentOverrides
            )
            process.standardOutput = stdout
            process.standardError = stderr

            stdout.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }

                if let chunk = String(data: data, encoding: .utf8), !chunk.isEmpty {
                    continuation.yield(chunk)
                }
            }

            stderr.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }

                processBox.appendStderr(data)
            }

            process.terminationHandler = { terminatedProcess in
                stdout.fileHandleForReading.readabilityHandler = nil
                stderr.fileHandleForReading.readabilityHandler = nil
                terminatedProcess.terminationHandler = nil

                let remainingStdout = stdout.fileHandleForReading.readDataToEndOfFile()
                if let chunk = String(data: remainingStdout, encoding: .utf8), !chunk.isEmpty {
                    continuation.yield(chunk)
                }

                let remainingStderr = stderr.fileHandleForReading.readDataToEndOfFile()
                if !remainingStderr.isEmpty {
                    processBox.appendStderr(remainingStderr)
                }

                processBox.clearProcess()

                if terminatedProcess.terminationStatus == 0 || processBox.wasCancelled {
                    continuation.finish()
                } else {
                    let message = processBox.stderrText.isEmpty
                        ? "kubectl logs exited with status \(terminatedProcess.terminationStatus)"
                        : processBox.stderrText
                    continuation.finish(throwing: PodLogStreamingError.commandFailed(message))
                }
            }

            processBox.process = process

            do {
                try process.run()
            } catch {
                stdout.fileHandleForReading.readabilityHandler = nil
                stderr.fileHandleForReading.readabilityHandler = nil
                continuation.finish(throwing: PodLogStreamingError.launchFailed)
            }

            continuation.onTermination = { _ in
                processBox.cancel()
            }
        }
    }
}

private final class PodLogProcessBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stderrData = Data()
    private var isCancelled = false
    var process: Process?

    var wasCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancelled
    }

    var stderrText: String {
        lock.lock()
        defer { lock.unlock() }
        return String(data: stderrData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func appendStderr(_ data: Data) {
        lock.lock()
        stderrData.append(data)
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        let process = process
        lock.unlock()

        guard let process, process.isRunning else {
            return
        }

        process.terminate()
    }

    func clearProcess() {
        lock.lock()
        process = nil
        lock.unlock()
    }
}

private extension Bool {
    var asInt: Int {
        self ? 1 : 0
    }
}
