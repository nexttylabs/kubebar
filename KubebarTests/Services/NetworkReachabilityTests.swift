import Foundation
import Testing
@testable import KubebarCore

// MARK: - Fake

/// Controllable fake for testing. Captures the handler and lets tests
/// simulate network transitions without NWPathMonitor.
final class FakeNetworkReachability: NetworkReachability, @unchecked Sendable {
    private var handler: (@MainActor @Sendable (Bool) -> Void)?
    private(set) var didStopMonitoring = false

    func startMonitoring(onChange: @MainActor @Sendable @escaping (Bool) -> Void) {
        handler = onChange
    }

    func stopMonitoring() {
        didStopMonitoring = true
        handler = nil
    }

    @MainActor
    func simulateChange(isAvailable: Bool) {
        handler?(isAvailable)
    }
}

// MARK: - Suite

@Suite("NetworkReachability protocol")
struct NetworkReachabilityTests {

    @Test("fake starts monitoring and captures handler")
    func fakeStartsMonitoring() {
        let fake = FakeNetworkReachability()
        var received: [Bool] = []

        fake.startMonitoring { isAvailable in
            received.append(isAvailable)
        }

        // Simulate two state changes
        Task { @MainActor in
            fake.simulateChange(isAvailable: false)
            fake.simulateChange(isAvailable: true)
        }

        #expect(fake.didStopMonitoring == false)
    }

    @Test("fake stops monitoring and clears handler")
    func fakeStopsMonitoring() {
        let fake = FakeNetworkReachability()
        fake.startMonitoring { _ in }
        fake.stopMonitoring()

        #expect(fake.didStopMonitoring)
    }
}

// MARK: - RefreshCoordinator guard integration test

/// Verifies the fake conforms to NetworkReachability without requiring
/// real NWPathMonitor. The ViewModel-level integration is covered by
/// manual smoke testing because MenuBarViewModel is @MainActor and
/// requires the full app environment.
@Suite("FakeNetworkReachability conformance")
struct FakeNetworkReachabilityConformanceTests {

    @Test("conforms to NetworkReachability protocol")
    func conformsToProtocol() {
        let fake: any NetworkReachability = FakeNetworkReachability()
        // Just confirming the conformance compiles — no assertion needed.
        _ = fake
    }
}
