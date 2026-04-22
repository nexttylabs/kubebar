import Foundation

public struct CommandRequest: Equatable, Sendable {
    public let executable: String
    public let arguments: [String]
    public let timeoutSeconds: TimeInterval

    public init(executable: String, arguments: [String], timeoutSeconds: TimeInterval = 10) {
        self.executable = executable
        self.arguments = arguments
        self.timeoutSeconds = timeoutSeconds
    }
}

public struct CommandResult: Equatable, Sendable {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32

    public init(stdout: String, stderr: String, exitCode: Int32) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
    }

    public init(output: String, error: String, exitCode: Int32) {
        self.init(stdout: output, stderr: error, exitCode: exitCode)
    }

    public var standardOutput: String {
        stdout
    }

    public var standardError: String {
        stderr
    }
}

public protocol CommandRunning: Sendable {
    func run(_ request: CommandRequest) throws -> CommandResult
}

public enum CommandRunnerError: Error, Equatable, Sendable {
    case launchFailed
    case timedOut
}

public final class ProcessCommandRunner: CommandRunning, @unchecked Sendable {
    static let defaultExecutableSearchPaths = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/usr/bin",
        "/bin",
        "/usr/sbin",
        "/sbin"
    ]

    private let additionalExecutableSearchPaths: [String]

    public convenience init() {
        self.init(additionalExecutableSearchPaths: Self.defaultExecutableSearchPaths)
    }

    init(additionalExecutableSearchPaths: [String]) {
        self.additionalExecutableSearchPaths = additionalExecutableSearchPaths
    }

    public func run(_ request: CommandRequest) throws -> CommandResult {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        let finished = DispatchSemaphore(value: 0)
        let outputReaders = DispatchGroup()
        let stdoutData = LockedDataBuffer()
        let stderrData = LockedDataBuffer()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [request.executable] + request.arguments
        process.environment = Self.launchEnvironment(
            base: ProcessInfo.processInfo.environment,
            additionalExecutableSearchPaths: additionalExecutableSearchPaths
        )
        process.standardOutput = stdout
        process.standardError = stderr

        process.terminationHandler = { _ in
            finished.signal()
        }

        do {
            try process.run()
        } catch {
            throw CommandRunnerError.launchFailed
        }

        outputReaders.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            stdoutData.set(stdout.fileHandleForReading.readDataToEndOfFile())
            outputReaders.leave()
        }

        outputReaders.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            stderrData.set(stderr.fileHandleForReading.readDataToEndOfFile())
            outputReaders.leave()
        }

        let deadline = Date().addingTimeInterval(request.timeoutSeconds)
        while finished.wait(timeout: .now() + 0.1) == .timedOut {
            if Task.isCancelled {
                process.terminate()
                process.waitUntilExit()
                outputReaders.wait()
                throw CancellationError()
            }

            if Date() >= deadline {
                process.terminate()
                process.waitUntilExit()
                outputReaders.wait()
                throw CommandRunnerError.timedOut
            }
        }

        process.waitUntilExit()
        outputReaders.wait()

        return CommandResult(
            stdout: String(data: stdoutData.data, encoding: .utf8) ?? "",
            stderr: String(data: stderrData.data, encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
    }

    static func launchEnvironment(
        base: [String: String],
        additionalExecutableSearchPaths: [String] = defaultExecutableSearchPaths
    ) -> [String: String] {
        var environment = base
        let inheritedSearchPaths = base["PATH"]?.split(separator: ":").map(String.init) ?? []
        var seenSearchPaths = Set<String>()
        var searchPaths: [String] = []

        for path in inheritedSearchPaths + additionalExecutableSearchPaths {
            let normalizedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedPath.isEmpty, seenSearchPaths.insert(normalizedPath).inserted else {
                continue
            }

            searchPaths.append(normalizedPath)
        }

        environment["PATH"] = searchPaths.joined(separator: ":")
        return environment
    }
}

private final class LockedDataBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = Data()

    var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func set(_ data: Data) {
        lock.lock()
        storage = data
        lock.unlock()
    }
}
