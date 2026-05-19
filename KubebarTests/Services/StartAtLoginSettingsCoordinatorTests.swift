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
