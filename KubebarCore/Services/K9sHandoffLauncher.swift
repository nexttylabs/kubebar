import Foundation

public enum K9sHandoffLauncherError: Error, Equatable, Sendable {
    case failed
}

public protocol K9sHandoffLaunching: Sendable {
    func launch(contextName: String, namespace: String) throws
}

public final class K9sHandoffLauncher: K9sHandoffLaunching {
    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func launch(contextName: String, namespace: String) throws {
        let path = ProcessCommandRunner.launchEnvironment(base: ProcessInfo.processInfo.environment)["PATH"]
            ?? "/usr/bin:/bin:/usr/sbin:/sbin"

        let request = CommandRequest(
            executable: "osascript",
            arguments: [
                "-e",
                launchScript(),
                contextName,
                namespace,
                path
            ],
            timeoutSeconds: 12
        )

        guard let result = try? runner.run(request), result.exitCode == 0 else {
            throw K9sHandoffLauncherError.failed
        }
    }

    private func launchScript() -> String {
        """
        on run argv
            set contextName to item 1 of argv
            set namespaceName to item 2 of argv
            set pathEnvironment to item 3 of argv

            tell application "Terminal"
                set k9sCommand to "export PATH=" & quoted form of pathEnvironment & "; exec k9s --context " & quoted form of contextName & " -n " & quoted form of namespaceName
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
