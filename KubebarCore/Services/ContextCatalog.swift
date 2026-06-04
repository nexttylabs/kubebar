import Foundation

public enum KubectlCommandError: Error, Equatable, Sendable {
    case failed(String)
}

public struct ContextCatalog: Sendable {
    private let runner: CommandRunning
    private let fixedKubectlEnvironment: KubectlEnvironment?
    private let baseEnvironment: [String: String]
    private let shellLookup: any ShellEnvironmentLookup
    private let compatibilityConfig: AppConfig?

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
        self.fixedKubectlEnvironment = nil
        self.baseEnvironment = ProcessInfo.processInfo.environment
        self.shellLookup = LoginShellEnvironmentLookup()
        self.compatibilityConfig = nil
    }

    public init(
        runner: CommandRunning = ProcessCommandRunner(),
        kubectlEnvironment: KubectlEnvironment
    ) {
        self.runner = runner
        self.fixedKubectlEnvironment = kubectlEnvironment
        self.baseEnvironment = [:]
        self.shellLookup = LoginShellEnvironmentLookup()
        self.compatibilityConfig = nil
    }

    public init(
        runner: CommandRunning = ProcessCommandRunner(),
        config: AppConfig,
        baseEnvironment: [String: String] = ProcessInfo.processInfo.environment,
        shellLookup: any ShellEnvironmentLookup = LoginShellEnvironmentLookup()
    ) {
        self.runner = runner
        self.fixedKubectlEnvironment = nil
        self.baseEnvironment = baseEnvironment
        self.shellLookup = shellLookup
        self.compatibilityConfig = config
    }

    public func listContexts(config: AppConfig) throws -> [String] {
        let result = try runner.run(
            CommandRequest(
                executable: "kubectl",
                arguments: ["config", "get-contexts", "-o", "name"],
                environmentOverrides: kubectlEnvironment(for: config).environmentOverrides
            )
        )

        guard result.exitCode == 0 else {
            let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw KubectlCommandError.failed(message.isEmpty ? "kubectl failed" : message)
        }

        return result.stdout
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    public func listContexts() throws -> [String] {
        try listContexts(config: compatibilityConfig ?? AppConfig())
    }

    private func kubectlEnvironment(for config: AppConfig) -> KubectlEnvironment {
        fixedKubectlEnvironment ?? KubectlEnvironment(
            config: config,
            baseEnvironment: baseEnvironment,
            shellLookup: shellLookup
        )
    }
}
