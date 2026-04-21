import Foundation

public struct RefreshTicket<Configuration: Equatable & Sendable>: Equatable, Sendable {
    fileprivate let generation: Int
    fileprivate let config: Configuration
}

public struct RefreshGate: Sendable {
    private var isInFlight: Bool
    private var generation: Int
    private var hasPendingRefresh: Bool

    public init(isInFlight: Bool = false, generation: Int = 0, hasPendingRefresh: Bool = false) {
        self.isInFlight = isInFlight
        self.generation = generation
        self.hasPendingRefresh = hasPendingRefresh
    }

    public mutating func begin() -> Bool {
        guard !isInFlight else {
            return false
        }

        isInFlight = true
        return true
    }

    public mutating func begin<Configuration: Equatable & Sendable>(
        config: Configuration
    ) -> RefreshTicket<Configuration>? {
        guard begin() else {
            return nil
        }

        return RefreshTicket(generation: generation, config: config)
    }

    public mutating func invalidate() {
        generation += 1
    }

    public mutating func requestPendingRefresh() {
        guard isInFlight else {
            return
        }

        hasPendingRefresh = true
    }

    public func shouldApply<Configuration: Equatable & Sendable>(
        _ ticket: RefreshTicket<Configuration>,
        currentConfig: Configuration
    ) -> Bool {
        ticket.generation == generation && ticket.config == currentConfig
    }

    public mutating func finish() {
        isInFlight = false
    }

    public mutating func finishAndConsumePendingRefresh() -> Bool {
        finish()

        guard hasPendingRefresh else {
            return false
        }

        hasPendingRefresh = false
        return true
    }
}
