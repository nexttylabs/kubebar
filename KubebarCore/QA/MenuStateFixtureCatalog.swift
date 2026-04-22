import Foundation

public enum MenuQAState: String, CaseIterable, Sendable {
    case healthy
    case watch
    case bad
    case staleRefreshFailure = "stale-refresh-failure"
    case staleAgeOut = "stale-age-out"
    case firstUse = "first-use"
    case emptyWatchlist = "empty-watchlist"
    case kubectlFailure = "kubectl-failure"
}

public struct MenuStateFixture: Equatable, Sendable {
    public let id: MenuQAState
    public let display: MenuDisplayModel
    public let setupState: SetupFlowState
    public let isShowingSetup: Bool
    public let reproductionSteps: String
    public let expectedBehavior: String
    public let evidencePath: String
    public let limitations: String
    public let followUpRisk: String

    public init(
        id: MenuQAState,
        display: MenuDisplayModel,
        setupState: SetupFlowState,
        isShowingSetup: Bool,
        reproductionSteps: String,
        expectedBehavior: String,
        evidencePath: String,
        limitations: String,
        followUpRisk: String
    ) {
        self.id = id
        self.display = display
        self.setupState = setupState
        self.isShowingSetup = isShowingSetup
        self.reproductionSteps = reproductionSteps
        self.expectedBehavior = expectedBehavior
        self.evidencePath = evidencePath
        self.limitations = limitations
        self.followUpRisk = followUpRisk
    }
}

public enum MenuStateFixtureCatalog {
    public static let requiredStates = MenuQAState.allCases

    public static func fixture(for state: MenuQAState) -> MenuStateFixture {
        switch state {
        case .healthy:
            return makeFixture(
                id: state,
                display: evaluator.evaluate(snapshot: healthySnapshot(), now: now),
                expectedBehavior: "Overview shows OK with healthy counters and watched namespaces.",
                limitations: "Requires visible menu inspection to confirm the rendered menu bar window."
            )
        case .watch:
            return makeFixture(
                id: state,
                display: evaluator.evaluate(snapshot: watchSnapshot(), now: now),
                expectedBehavior: "Overview shows Watch with warning context and non-healthy attention.",
                limitations: "Requires visible menu inspection to confirm warning copy and ordering."
            )
        case .bad:
            return makeFixture(
                id: state,
                display: evaluator.evaluate(snapshot: badSnapshot(), now: now),
                expectedBehavior: "Overview shows Bad and prioritizes the broken watched target.",
                limitations: "Requires visible menu inspection to confirm the attention item is first."
            )
        case .staleRefreshFailure:
            return makeFixture(
                id: state,
                display: evaluator.evaluate(
                    snapshot: nil,
                    previousSnapshot: healthySnapshot(),
                    failure: RefreshFailure(reason: "Refresh failed; showing last known status."),
                    now: now
                ),
                expectedBehavior: "Overview shows Stale while preserving the last known healthy counters.",
                limitations: "Requires visible menu inspection to confirm stale data is not presented as current."
            )
        case .staleAgeOut:
            return makeFixture(
                id: state,
                display: evaluator.evaluate(
                    snapshot: healthySnapshot(),
                    now: Date(timeIntervalSince1970: 250),
                    staleAfterSeconds: 120
                ),
                expectedBehavior: "Overview shows Stale because the last successful refresh is too old.",
                limitations: "Requires visible menu inspection to confirm the stale banner is visible."
            )
        case .firstUse:
            return makeFixture(
                id: state,
                display: setupRequiredDisplay(reason: "No saved context yet."),
                setupState: firstUseSetupState(),
                isShowingSetup: true,
                expectedBehavior: "Menu opens the setup-required state before any saved context exists.",
                limitations: "Requires visible menu inspection to confirm setup appears instead of a healthy menu."
            )
        case .emptyWatchlist:
            return makeFixture(
                id: state,
                display: setupRequiredDisplay(reason: "No watched namespace selected."),
                setupState: emptyWatchlistSetupState(),
                isShowingSetup: true,
                expectedBehavior: "Menu opens the setup-required state when the QA fixture context has no selected namespaces.",
                limitations: "Requires visible menu inspection to confirm the empty watchlist action is visible."
            )
        case .kubectlFailure:
            return makeFixture(
                id: state,
                display: evaluator.evaluate(
                    snapshot: nil,
                    previousSnapshot: healthySnapshot(),
                    failure: RefreshFailure(reason: "Cluster refresh failed; showing last known status."),
                    now: now
                ),
                expectedBehavior: "Overview shows Stale with a safe failure message and retained prior status.",
                limitations: "Requires visible menu inspection to confirm no sensitive failure detail is shown."
            )
        }
    }

    public static func fixture(named rawValue: String) -> MenuStateFixture? {
        guard let state = MenuQAState(rawValue: rawValue) else {
            return nil
        }

        return fixture(for: state)
    }

    private static let evaluator = HealthEvaluator()
    private static let capturedAt = Date(timeIntervalSince1970: 100)
    private static let warningObservedAt = Date(timeIntervalSince1970: 190)
    private static let now = Date(timeIntervalSince1970: 220)

    private static func makeFixture(
        id: MenuQAState,
        display: MenuDisplayModel,
        setupState: SetupFlowState = configuredSetupState(),
        isShowingSetup: Bool = false,
        expectedBehavior: String,
        limitations: String
    ) -> MenuStateFixture {
        MenuStateFixture(
            id: id,
            display: display,
            setupState: setupState,
            isShowingSetup: isShowingSetup,
            reproductionSteps: "./scripts/compile-and-run.sh --qa-state \(id.rawValue)",
            expectedBehavior: expectedBehavior,
            evidencePath: "docs/assets/qa/phase-07-\(id.rawValue).png",
            limitations: limitations,
            followUpRisk: "Do not mark this state complete without visible menu evidence or an explicit human-needed note."
        )
    }

    private static func healthySnapshot() -> ClusterSnapshot {
        ClusterSnapshot(
            contextName: "QA fixture",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(
                    target: .namespace("qa-api"),
                    state: .ok,
                    reason: "6/6 watched pods running"
                ),
                TrackedItemStatus(
                    target: .namespace("qa-monitoring"),
                    state: .ok,
                    reason: "3/3 watched pods running"
                )
            ]),
            capturedAt: capturedAt
        )
    }

    private static func watchSnapshot() -> ClusterSnapshot {
        ClusterSnapshot(
            contextName: "QA fixture",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 11, total: 12)),
            warningEventsSection: .available([
                WarningEventRecord(
                    reason: "BackOff",
                    namespace: "qa-api",
                    objectKind: "Pod",
                    objectName: "qa-checkout-7f9",
                    message: "Container is backing off after repeated restarts.",
                    observedAt: warningObservedAt,
                    count: 2
                )
            ]),
            workloadsSection: .available([
                TrackedItemStatus(
                    target: .namespace("qa-api"),
                    state: .watch,
                    reason: "1 pod restarting",
                    affectedPodCount: 1,
                    examplePodNames: ["qa-checkout-7f9"],
                    latestWarning: WarningEventRecord(
                        reason: "BackOff",
                        namespace: "qa-api",
                        objectKind: "Pod",
                        objectName: "qa-checkout-7f9",
                        message: "Container is backing off after repeated restarts.",
                        observedAt: warningObservedAt,
                        count: 2
                    )
                )
            ]),
            capturedAt: capturedAt
        )
    }

    private static func badSnapshot() -> ClusterSnapshot {
        ClusterSnapshot(
            contextName: "QA fixture",
            nodesSection: .available(NodeSummary(ready: 2, total: 3)),
            podsSection: .available(PodSummary(running: 10, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(
                    target: .namespace("qa-payments"),
                    state: .bad,
                    reason: "2 pods unavailable",
                    affectedPodCount: 2,
                    examplePodNames: ["qa-payments-api-0", "qa-payments-worker-1"]
                ),
                TrackedItemStatus(
                    target: .namespace("qa-api"),
                    state: .ok,
                    reason: "6/6 watched pods running"
                )
            ]),
            capturedAt: capturedAt
        )
    }

    private static func setupRequiredDisplay(reason: String) -> MenuDisplayModel {
        evaluator.evaluate(
            snapshot: nil,
            failure: RefreshFailure(reason: reason),
            now: now
        )
    }

    private static func configuredSetupState() -> SetupFlowState {
        SetupFlowState(
            selectedContext: "QA fixture",
            availableContexts: ["QA fixture", "QA standby"],
            watchlist: WatchlistSelectionState(
                availableNamespaces: ["qa-api", "qa-monitoring", "qa-payments"],
                selectedTargets: [.namespace("qa-api"), .namespace("qa-monitoring")]
            ),
            refreshCadence: .oneMinute
        )
    }

    private static func firstUseSetupState() -> SetupFlowState {
        SetupFlowState(
            selectedContext: nil,
            availableContexts: ["QA fixture", "QA standby"],
            watchlist: WatchlistSelectionState(availableNamespaces: []),
            refreshCadence: .oneMinute
        )
    }

    private static func emptyWatchlistSetupState() -> SetupFlowState {
        SetupFlowState(
            selectedContext: "QA fixture",
            availableContexts: ["QA fixture", "QA standby"],
            watchlist: WatchlistSelectionState(
                availableNamespaces: ["qa-api", "qa-monitoring", "qa-payments"],
                selectedTargets: []
            ),
            refreshCadence: .oneMinute
        )
    }
}
