import Foundation

public struct StartAtLoginState: Equatable, Sendable {
    public static let updateFailureMessage = "Could not update Start at Login. Try again."

    public let isEnabled: Bool
    public let message: String?

    public init(isEnabled: Bool = false, message: String? = nil) {
        self.isEnabled = isEnabled
        self.message = message
    }
}

public struct HealthShiftAlertsState: Equatable, Sendable {
    public static let authorizationDeniedMessage = "Could not enable notifications. Check macOS notification settings."

    public let isEnabled: Bool
    public let message: String?

    public init(isEnabled: Bool = false, message: String? = nil) {
        self.isEnabled = isEnabled
        self.message = message
    }
}

public struct HealthShiftAlertSettingsRequestGate: Equatable, Sendable {
    public struct Token: Equatable, Sendable {
        fileprivate let value: Int
    }

    private var latestValue: Int

    public init() {
        self.latestValue = 0
    }

    public mutating func beginRequest() -> Token {
        latestValue += 1
        return Token(value: latestValue)
    }

    public mutating func invalidate() {
        latestValue += 1
    }

    public func accepts(_ token: Token) -> Bool {
        token.value == latestValue
    }
}
