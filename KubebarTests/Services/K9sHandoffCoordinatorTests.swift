import Foundation
import Testing
@testable import KubebarCore

@MainActor
@Suite("k9s handoff coordinator")
struct K9sHandoffCoordinatorTests {
    @Test("opening target shows opening state then returns to idle")
    func openingTargetReturnsToIdle() async {
        let launcher = ControlledLauncher(delayNanoseconds: 100_000_000)
        let coordinator = K9sHandoffCoordinator(launcher: launcher)
        let target = OverviewK9sHandoff(
            target: K9sHandoffTarget(contextName: "prod", namespace: "api"),
            actionLabel: "Open in k9s",
            helpText: "Open watched target in k9s",
            accessibilityLabel: "Open watched target in k9s"
        )

        coordinator.open(for: target)
        #expect(coordinator.state == .opening(target: target))

        launcher.release()

        #expect(await waitForState(coordinator, expected: .idle, timeout: .seconds(1)))
        #expect(coordinator.state == .idle)
        #expect(launcher.callCount == 1)
    }

    @Test("repeated activation while opening does not retry launch")
    func repeatedActivationIsIgnoredWhileOpening() async {
        let launcher = ControlledLauncher(delayNanoseconds: 100_000_000)
        let coordinator = K9sHandoffCoordinator(launcher: launcher)
        let target = OverviewK9sHandoff(
            target: K9sHandoffTarget(contextName: "prod", namespace: "api"),
            actionLabel: "Open in k9s",
            helpText: "Open watched target in k9s",
            accessibilityLabel: "Open watched target in k9s"
        )

        coordinator.open(for: target)
        coordinator.open(for: target)

        #expect(coordinator.state == .opening(target: target))
        launcher.release()
        #expect(await waitForState(coordinator, expected: .idle, timeout: .seconds(1)))
        #expect(launcher.callCount == 1)
    }

    @Test("failure publishes safe message and stays target-specific")
    func launchFailureIsScopedToTarget() async {
        let launcher = ControlledLauncher(result: .failure(K9sHandoffLauncherError.failed), delayNanoseconds: 100_000_000)
        let coordinator = K9sHandoffCoordinator(launcher: launcher)
        let target = OverviewK9sHandoff(
            target: K9sHandoffTarget(contextName: "prod", namespace: "api"),
            actionLabel: "Open in k9s",
            helpText: "Open watched target in k9s",
            accessibilityLabel: "Open watched target in k9s"
        )

        coordinator.open(for: target)
        #expect(coordinator.state == .opening(target: target))
        launcher.release()
        #expect(await waitForState(coordinator, expected: .failed(target: target, message: "Could not open k9s for prod/api"), timeout: .seconds(1)))
        #expect(coordinator.state == .failed(target: target, message: "Could not open k9s for prod/api"))
    }

    @Test("state clears when target disappears")
    func stateClearsWhenTargetDisappears() {
        let launcher = ControlledLauncher()
        let coordinator = K9sHandoffCoordinator(launcher: launcher)
        let target = OverviewK9sHandoff(
            target: K9sHandoffTarget(contextName: "prod", namespace: "api"),
            actionLabel: "Open in k9s",
            helpText: "Open watched target in k9s",
            accessibilityLabel: "Open watched target in k9s"
        )

        coordinator.open(for: target)
        coordinator.resetIfTargetUnavailable(nil)
        #expect(coordinator.state == .idle)
    }

    @Test("handoff state exposes feedback message for matching target only")
    func feedbackMessageTargetsOnlyTheMatchingLaunchTarget() {
        let matchingTarget = OverviewK9sHandoff(
            target: K9sHandoffTarget(contextName: "prod", namespace: "api"),
            actionLabel: "Open in k9s",
            helpText: "Open watched target in k9s",
            accessibilityLabel: "Open watched target in k9s"
        )
        let otherTarget = OverviewK9sHandoff(
            target: K9sHandoffTarget(contextName: "stage", namespace: "api"),
            actionLabel: "Open in k9s",
            helpText: "Open watched target in k9s",
            accessibilityLabel: "Open watched target in k9s"
        )

        #expect(K9sHandoffLaunchState.idle.feedbackMessage(for: matchingTarget) == nil)
        #expect(K9sHandoffLaunchState.opening(target: matchingTarget).feedbackMessage(for: matchingTarget) == "Opening k9s...")
        #expect(K9sHandoffLaunchState.opening(target: matchingTarget).feedbackMessage(for: otherTarget) == nil)
        #expect(
            K9sHandoffLaunchState.failed(
                target: matchingTarget,
                message: "Could not open k9s for prod/api"
            ).feedbackMessage(for: matchingTarget) == "Could not open k9s for prod/api"
        )
        #expect(
            K9sHandoffLaunchState.failed(
                target: matchingTarget,
                message: "Could not open k9s for prod/api"
            ).feedbackMessage(for: otherTarget) == nil
        )
    }

    @Test("opening feedback flag is target-specific")
    func openingStateIsOpeningOnlyForTheMatchingTarget() {
        let matchingTarget = OverviewK9sHandoff(
            target: K9sHandoffTarget(contextName: "prod", namespace: "api"),
            actionLabel: "Open in k9s",
            helpText: "Open watched target in k9s",
            accessibilityLabel: "Open watched target in k9s"
        )
        let otherTarget = OverviewK9sHandoff(
            target: K9sHandoffTarget(contextName: "stage", namespace: "api"),
            actionLabel: "Open in k9s",
            helpText: "Open watched target in k9s",
            accessibilityLabel: "Open watched target in k9s"
        )
        let openingState = K9sHandoffLaunchState.opening(target: matchingTarget)

        #expect(openingState.isOpeningForSameTarget(matchingTarget))
        #expect(!openingState.isOpeningForSameTarget(otherTarget))
        #expect(!K9sHandoffLaunchState.idle.isOpeningForSameTarget(matchingTarget))
    }
}

private final class ControlledLauncher: K9sHandoffLaunching, @unchecked Sendable {
    private let result: Result<Void, Error>
    private let delayNanoseconds: UInt64
    private let releaseGate = DispatchSemaphore(value: 0)
    private(set) var callCount = 0

    init(
        result: Result<Void, Error> = .success(()),
        delayNanoseconds: UInt64 = 0
    ) {
        self.result = result
        self.delayNanoseconds = delayNanoseconds
    }

    func launch(contextName: String, namespace: String) throws {
        _ = contextName
        _ = namespace
        callCount += 1

        if delayNanoseconds > 0 {
            releaseGate.wait()
            Thread.sleep(forTimeInterval: TimeInterval(delayNanoseconds) / 1_000_000_000)
        }

        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func release() {
        releaseGate.signal()
    }
}

@MainActor
private func waitForState(
    _ coordinator: K9sHandoffCoordinator,
    expected: K9sHandoffLaunchState,
    timeout: Duration
) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)

    while coordinator.state != expected && clock.now < deadline {
        try? await Task.sleep(for: .milliseconds(20))
    }

    return coordinator.state == expected
}
