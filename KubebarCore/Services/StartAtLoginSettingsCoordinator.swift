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

public protocol HealthShiftAlertAuthorizing: Sendable {
    func requestAuthorization() async -> Bool
}

public protocol HealthShiftAlertDelivering: Sendable {
    func deliver(_ alert: HealthShiftAlert) async
}

public typealias HealthShiftAlertNotifying = HealthShiftAlertAuthorizing & HealthShiftAlertDelivering

public struct HealthShiftAlertSettingsCoordinator: Sendable {
    private let authorizer: any HealthShiftAlertAuthorizing

    public init(authorizer: any HealthShiftAlertAuthorizing) {
        self.authorizer = authorizer
    }

    public func setEnabled(_ isEnabled: Bool) async -> HealthShiftAlertsState {
        guard isEnabled else {
            return HealthShiftAlertsState(isEnabled: false)
        }

        guard await authorizer.requestAuthorization() else {
            return HealthShiftAlertsState(
                isEnabled: false,
                message: HealthShiftAlertsState.authorizationDeniedMessage
            )
        }

        return HealthShiftAlertsState(isEnabled: true)
    }
}
