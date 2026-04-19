import Foundation

public enum KubectlCommandError: Error, Equatable {
    case failed(String)
}

public struct ContextCatalog: Sendable {
    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func listContexts() throws -> [String] {
        let result = try runner.run(
            CommandRequest(executable: "kubectl", arguments: ["config", "get-contexts", "-o", "name"])
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
}
