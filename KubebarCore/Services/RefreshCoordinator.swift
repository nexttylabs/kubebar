import Foundation

public struct RefreshResult: Equatable, Sendable {
    public let snapshot: ClusterSnapshot?
    public let display: MenuDisplayModel
}

public struct RefreshCoordinator: Sendable {
    private let reader: any ClusterReading
    private let evaluator: HealthEvaluator

    public init(reader: any ClusterReading = KubectlClusterReader(), evaluator: HealthEvaluator = HealthEvaluator()) {
        self.reader = reader
        self.evaluator = evaluator
    }

    public func refresh(config: AppConfig, previousSnapshot: ClusterSnapshot?, now: Date) -> RefreshResult {
        guard let contextName = config.selectedContext, !config.watchTargets.isEmpty else {
            return RefreshResult(
                snapshot: nil,
                display: evaluator.evaluate(
                    snapshot: nil,
                    previousSnapshot: nil,
                    failure: RefreshFailure(reason: "Choose a cluster context and watchlist to begin"),
                    now: now
                )
            )
        }

        do {
            let snapshot = try reader.readSnapshot(
                contextName: contextName,
                watchTargets: config.watchTargets,
                now: now
            )

            return RefreshResult(
                snapshot: snapshot,
                display: evaluator.evaluate(snapshot: snapshot, now: now)
            )
        } catch {
            return RefreshResult(
                snapshot: previousSnapshot,
                display: evaluator.evaluate(
                    snapshot: nil,
                    previousSnapshot: previousSnapshot,
                    failure: RefreshFailure(reason: failureReason(from: error)),
                    now: now
                )
            )
        }
    }

    private func failureReason(from error: Error) -> String {
        if case let KubectlCommandError.failed(reason) = error {
            return reason
        }

        return error.localizedDescription
    }
}
