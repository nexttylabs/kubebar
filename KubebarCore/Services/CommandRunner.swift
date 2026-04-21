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
}

public protocol CommandRunning: Sendable {
    func run(_ request: CommandRequest) throws -> CommandResult
}

public enum CommandRunnerError: Error, Equatable, Sendable {
    case launchFailed
    case timedOut
}

public final class ProcessCommandRunner: CommandRunning, @unchecked Sendable {
    public init() {}

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
