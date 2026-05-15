import Foundation

public enum K9sHandoffLauncherError: Error, Equatable, Sendable {
    case failed
}

public protocol K9sHandoffLaunching: Sendable {
    func launch(target: K9sHandoffTarget) throws
}

public final class K9sHandoffLauncher: K9sHandoffLaunching {
    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func launch(target: K9sHandoffTarget) throws {
        let path = ProcessCommandRunner.launchEnvironment(base: ProcessInfo.processInfo.environment)["PATH"]
            ?? "/usr/bin:/bin:/usr/sbin:/sbin"

        let request = CommandRequest(
            executable: "osascript",
            arguments: [
                "-e",
                launchScript(),
                target.contextName,
                target.resource.namespace ?? "",
                resourceCommand(for: target.resource) ?? "",
                path
            ],
            timeoutSeconds: 12
        )

        guard let result = try? runner.run(request), result.exitCode == 0 else {
            throw K9sHandoffLauncherError.failed
        }
    }

    public func launch(contextName: String, namespace: String) throws {
        try launch(target: K9sHandoffTarget(contextName: contextName, namespace: namespace))
    }

    private func resourceCommand(for resource: K9sResourceTarget) -> String? {
        switch resource {
        case .namespace:
            nil
        case let .workload(_, _, kind):
            kind.kubectlResource
        case .podList:
            "pods"
        case .nodeList:
            "nodes"
        }
    }

    private func launchScript() -> String {
        """
        on run argv
            set contextName to item 1 of argv
            set namespaceName to item 2 of argv
            set resourceCommand to item 3 of argv
            set pathEnvironment to item 4 of argv

            tell application "Terminal"
                set k9sCommand to "export PATH=" & quoted form of pathEnvironment & "; exec k9s --context " & quoted form of contextName
                if namespaceName is not "" then
                    set k9sCommand to k9sCommand & " -n " & quoted form of namespaceName
                end if
                if resourceCommand is not "" then
                    set k9sCommand to k9sCommand & " -c " & quoted form of resourceCommand
                end if
                if (count of windows) is greater than 0 then
                    do script k9sCommand in front window
                else
                    do script k9sCommand
                end if
            end tell
        end run
        """
    }
}
