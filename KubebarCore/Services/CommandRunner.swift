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

public enum CommandRunnerError: Error, Equatable {
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

        let timeout = DispatchTime.now() + request.timeoutSeconds
        if finished.wait(timeout: timeout) == .timedOut {
            process.terminate()
            process.waitUntilExit()
            throw CommandRunnerError.timedOut
        }

        process.waitUntilExit()

        return CommandResult(
            stdout: String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            stderr: String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
    }
}
