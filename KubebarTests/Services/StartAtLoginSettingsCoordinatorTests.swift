import Testing
@testable import KubebarCore

@Suite("Start at Login settings coordinator")
struct StartAtLoginSettingsCoordinatorTests {
    @Test("current state reflects login item status")
    func currentStateReflectsLoginItemStatus() {
        let controller = FakeStartAtLoginController(isEnabled: true)
        let coordinator = StartAtLoginSettingsCoordinator(controller: controller)

        let state = coordinator.currentState()

        #expect(state.isEnabled)
        #expect(state.message == nil)
    }

    @Test("enabling registers the login item")
    func enablingRegistersLoginItem() {
        let controller = FakeStartAtLoginController(isEnabled: false)
        let coordinator = StartAtLoginSettingsCoordinator(controller: controller)

        let state = coordinator.setEnabled(true)

        #expect(controller.requests == [true])
        #expect(state.isEnabled)
        #expect(state.message == nil)
    }

    @Test("disabling unregisters the login item")
    func disablingUnregistersLoginItem() {
        let controller = FakeStartAtLoginController(isEnabled: true)
        let coordinator = StartAtLoginSettingsCoordinator(controller: controller)

        let state = coordinator.setEnabled(false)

        #expect(controller.requests == [false])
        #expect(!state.isEnabled)
        #expect(state.message == nil)
    }

    @Test("failed update rolls back to the actual status")
    func failedUpdateRollsBackToActualStatus() {
        let controller = FakeStartAtLoginController(isEnabled: false, shouldFail: true)
        let coordinator = StartAtLoginSettingsCoordinator(controller: controller)

        let state = coordinator.setEnabled(true)

        #expect(controller.requests == [true])
        #expect(!state.isEnabled)
        #expect(state.message == StartAtLoginState.updateFailureMessage)
    }
}

@Suite("Health State Shift Alerts settings coordinator")
struct HealthShiftAlertSettingsCoordinatorTests {
    @Test("enabling requests notification authorization")
    func enablingRequestsNotificationAuthorization() async {
        let authorizer = FakeHealthShiftAlertAuthorizer(grantsAuthorization: true)
        let coordinator = HealthShiftAlertSettingsCoordinator(authorizer: authorizer)

        let state = await coordinator.setEnabled(true)

        #expect(authorizer.authorizationRequestCount == 1)
        #expect(state.isEnabled)
        #expect(state.message == nil)
    }

    @Test("denied authorization keeps alerts off with feedback")
    func deniedAuthorizationKeepsAlertsOffWithFeedback() async {
        let authorizer = FakeHealthShiftAlertAuthorizer(grantsAuthorization: false)
        let coordinator = HealthShiftAlertSettingsCoordinator(authorizer: authorizer)

        let state = await coordinator.setEnabled(true)

        #expect(authorizer.authorizationRequestCount == 1)
        #expect(!state.isEnabled)
        #expect(state.message == HealthShiftAlertsState.authorizationDeniedMessage)
    }

    @Test("disabling alerts does not request authorization")
    func disablingAlertsDoesNotRequestAuthorization() async {
        let authorizer = FakeHealthShiftAlertAuthorizer(grantsAuthorization: true)
        let coordinator = HealthShiftAlertSettingsCoordinator(authorizer: authorizer)

        let state = await coordinator.setEnabled(false)

        #expect(authorizer.authorizationRequestCount == 0)
        #expect(!state.isEnabled)
        #expect(state.message == nil)
    }
}

@Suite("Health State Shift Alerts setting request gate")
struct HealthShiftAlertSettingsRequestGateTests {
    @Test("later toggle invalidates delayed authorization result")
    func laterToggleInvalidatesDelayedAuthorizationResult() {
        var gate = HealthShiftAlertSettingsRequestGate()

        let pendingEnable = gate.beginRequest()
        gate.invalidate()

        #expect(!gate.accepts(pendingEnable))
    }

    @Test("new enable request supersedes older authorization result")
    func newEnableRequestSupersedesOlderAuthorizationResult() {
        var gate = HealthShiftAlertSettingsRequestGate()

        let olderEnable = gate.beginRequest()
        let newerEnable = gate.beginRequest()

        #expect(!gate.accepts(olderEnable))
        #expect(gate.accepts(newerEnable))
    }
}

private final class FakeStartAtLoginController: StartAtLoginControlling, @unchecked Sendable {
    private(set) var isEnabled: Bool
    private(set) var requests: [Bool]
    private let shouldFail: Bool

    init(isEnabled: Bool, shouldFail: Bool = false) {
        self.isEnabled = isEnabled
        self.requests = []
        self.shouldFail = shouldFail
    }

    func setEnabled(_ isEnabled: Bool) throws {
        requests.append(isEnabled)

        guard !shouldFail else {
            throw FakeStartAtLoginError()
        }

        self.isEnabled = isEnabled
    }
}

private struct FakeStartAtLoginError: Error {}

private final class FakeHealthShiftAlertAuthorizer: HealthShiftAlertAuthorizing, @unchecked Sendable {
    private(set) var authorizationRequestCount = 0
    private let grantsAuthorization: Bool

    init(grantsAuthorization: Bool) {
        self.grantsAuthorization = grantsAuthorization
    }

    func requestAuthorization() async -> Bool {
        authorizationRequestCount += 1
        return grantsAuthorization
    }
}
