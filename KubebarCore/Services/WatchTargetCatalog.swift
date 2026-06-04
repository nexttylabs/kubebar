import Foundation

public protocol WatchTargetCataloging: Sendable {
    func listCandidates(config: AppConfig, contextName: String) async throws -> WatchlistCandidates
}

public struct WatchTargetCatalog: WatchTargetCataloging, Sendable {
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

    public func listCandidates(config: AppConfig, contextName: String) async throws -> WatchlistCandidates {
        try Task.checkCancellation()

        let json = try runKubectl(
            contextName: contextName,
            arguments: ["get", "namespaces", "-o", "json"],
            kubectlEnvironment: kubectlEnvironment(for: config)
        )
        try Task.checkCancellation()

        return WatchlistCandidates(namespaces: try decodeNamespaces(json).sorted())
    }

    public func listCandidates(contextName: String) async throws -> WatchlistCandidates {
        try await listCandidates(config: compatibilityConfig ?? AppConfig(), contextName: contextName)
    }

    private func runKubectl(
        contextName: String,
        arguments: [String],
        kubectlEnvironment: KubectlEnvironment
    ) throws -> String {
        let result: CommandResult
        do {
            result = try runner.run(
                CommandRequest(
                    executable: "kubectl",
                    arguments: ["--context", contextName] + arguments,
                    environmentOverrides: kubectlEnvironment.environmentOverrides
                )
            )
        } catch CommandRunnerError.timedOut {
            throw KubectlCommandError.failed("kubectl timed out")
        } catch CommandRunnerError.launchFailed {
            throw KubectlCommandError.failed("kubectl could not be launched")
        }

        guard result.exitCode == 0 else {
            let message = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw KubectlCommandError.failed(message.isEmpty ? "kubectl failed" : message)
        }

        return result.stdout
    }

    private func kubectlEnvironment(for config: AppConfig) -> KubectlEnvironment {
        fixedKubectlEnvironment ?? KubectlEnvironment(
            config: config,
            baseEnvironment: baseEnvironment,
            shellLookup: shellLookup
        )
    }

    private func decodeNamespaces(_ json: String) throws -> [String] {
        do {
            return try JSONDecoder()
                .decode(NamespaceList.self, from: Data(json.utf8))
                .items
                .map(\.metadata.name)
                .filter { !$0.isEmpty }
        } catch {
            throw KubectlCommandError.failed("invalid target JSON")
        }
    }
}

private struct NamespaceList: Decodable {
    let items: [NamespaceRecord]
}

private struct NamespaceRecord: Decodable {
    struct Metadata: Decodable {
        let name: String
    }

    let metadata: Metadata
}
