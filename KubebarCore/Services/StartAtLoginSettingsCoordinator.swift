import Foundation

public protocol StartAtLoginControlling: Sendable {
    var isEnabled: Bool { get }

    func setEnabled(_ isEnabled: Bool) throws
}

public struct StartAtLoginSettingsCoordinator: Sendable {
    private let controller: any StartAtLoginControlling

    public init(controller: any StartAtLoginControlling) {
        self.controller = controller
    }

    public func currentState() -> StartAtLoginState {
        StartAtLoginState(isEnabled: controller.isEnabled)
    }

    public func setEnabled(_ isEnabled: Bool) -> StartAtLoginState {
        do {
            try controller.setEnabled(isEnabled)
            return currentState()
        } catch {
            return StartAtLoginState(
                isEnabled: controller.isEnabled,
                message: StartAtLoginState.updateFailureMessage
            )
        }
    }
}
