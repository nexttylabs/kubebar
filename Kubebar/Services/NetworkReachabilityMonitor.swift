import Network
import KubebarCore

/// Wraps NWPathMonitor to deliver reachability changes on the main actor.
/// Uses @unchecked Sendable following the same pattern as ProcessCommandRunner,
/// since NWPathMonitor itself is not Sendable.
final class NetworkReachabilityMonitor: NetworkReachability, @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.nextty.kubebar.network-monitor", qos: .utility)

    func startMonitoring(onChange: @MainActor @Sendable @escaping (Bool) -> Void) {
        monitor.pathUpdateHandler = { path in
            let isAvailable = path.status == .satisfied
            Task { @MainActor in
                onChange(isAvailable)
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}
