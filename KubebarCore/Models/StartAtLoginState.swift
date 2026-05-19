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
