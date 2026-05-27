import Foundation

/// An injectable boundary for monitoring network reachability.
/// The real implementation wraps NWPathMonitor in the App layer;
/// tests use a controllable fake conformance.
public protocol NetworkReachability: Sendable {
    /// Start monitoring network reachability.
    /// The handler is called on the main actor whenever reachability changes,
    /// including an initial call with the current state.
    func startMonitoring(onChange: @MainActor @Sendable @escaping (Bool) -> Void)

    /// Stop monitoring and release any underlying resources.
    func stopMonitoring()
}
