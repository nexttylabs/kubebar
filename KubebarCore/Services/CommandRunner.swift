import Foundation

public struct CommandRequest: Equatable, Sendable {
    public let executable: String
    public let arguments: [String]
    public let environmentOverrides: [String: String]
    public let timeoutSeconds: TimeInterval

    public init(
        executable: String,
        arguments: [String],
        environmentOverrides: [String: String] = [:],
        timeoutSeconds: TimeInterval = 10
    ) {
        self.executable = executable
        self.arguments = arguments
        self.environmentOverrides = environmentOverrides
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

public protocol ShellEnvironmentLookup: Sendable {
    func value(for variable: String) -> String?
}

public struct LoginShellEnvironmentLookup: ShellEnvironmentLookup, Sendable {
    private let runner: CommandRunning
    private let shellPath: String

    public init(
        runner: CommandRunning = ProcessCommandRunner(),
        shellPath: String = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    ) {
        self.runner = runner
        self.shellPath = shellPath.isEmpty ? "/bin/zsh" : shellPath
    }

    public func value(for variable: String) -> String? {
        let marker = "__KUBEBAR_ENV__\(variable)__="
        let command = "command printf '%s%s\\n' '\(marker)' \"$\(variable)\""
        let request = CommandRequest(
            executable: shellPath,
            arguments: ["-lc", command],
            timeoutSeconds: 2
        )

        guard let result = try? runner.run(request), result.exitCode == 0 else {
            return nil
        }

        return result.stdout
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .reversed()
            .first(where: { $0.hasPrefix(marker) })
            .map { String($0.dropFirst(marker.count)).trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { $0.isEmpty ? nil : $0 }
    }
}

public struct KubectlEnvironment: Equatable, Sendable {
    public let environmentOverrides: [String: String]

    public init(environmentOverrides: [String: String]) {
        self.environmentOverrides = environmentOverrides
    }

    public init(
        baseEnvironment: [String: String] = ProcessInfo.processInfo.environment,
        shellLookup: any ShellEnvironmentLookup = LoginShellEnvironmentLookup()
    ) {
        if let kubeconfig = Self.detectedKubeconfig(
            from: baseEnvironment["KUBECONFIG"]
        ) ?? shellLookup.value(for: "KUBECONFIG") {
            self.environmentOverrides = ["KUBECONFIG": kubeconfig]
        } else {
            self.environmentOverrides = [:]
        }
    }

    public init(
        config: AppConfig,
        baseEnvironment: [String: String] = ProcessInfo.processInfo.environment,
        shellLookup: any ShellEnvironmentLookup = LoginShellEnvironmentLookup()
    ) {
        if let kubeconfig = Self.explicitKubeconfig(from: config.kubeconfigPaths)
            ?? Self.detectedKubeconfig(from: baseEnvironment["KUBECONFIG"])
            ?? shellLookup.value(for: "KUBECONFIG") {
            self.environmentOverrides = ["KUBECONFIG": kubeconfig]
        } else {
            self.environmentOverrides = [:]
        }
    }

    private static func explicitKubeconfig(from paths: [String]) -> String? {
        let normalizedPaths = paths
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !normalizedPaths.isEmpty else {
            return nil
        }

        return normalizedPaths.joined(separator: ":")
    }

    private static func detectedKubeconfig(from rawValue: String?) -> String? {
        guard let rawValue else {
            return nil
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
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
            additionalExecutableSearchPaths: additionalExecutableSearchPaths,
            environmentOverrides: request.environmentOverrides
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
        additionalExecutableSearchPaths: [String] = defaultExecutableSearchPaths,
        environmentOverrides: [String: String] = [:]
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

        for (key, value) in environmentOverrides {
            environment[key] = value
        }

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
