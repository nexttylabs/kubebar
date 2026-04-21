import Foundation

public struct RefreshGate: Sendable {
    private var isInFlight: Bool

    public init(isInFlight: Bool = false) {
        self.isInFlight = isInFlight
    }

    public mutating func begin() -> Bool {
        guard !isInFlight else {
            return false
        }

        isInFlight = true
        return true
    }

    public mutating func finish() {
        isInFlight = false
    }
}
