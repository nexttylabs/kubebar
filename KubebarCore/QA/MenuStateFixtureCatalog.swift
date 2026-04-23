import Foundation

public enum MenuQAState: String, CaseIterable, Sendable {
    case healthy
    case completedJobs = "completed-jobs"
    case watch
    case bad
    case staleRefreshFailure = "stale-refresh-failure"
    case staleAgeOut = "stale-age-out"
    case firstUse = "first-use"
    case emptyWatchlist = "empty-watchlist"
    case kubectlFailure = "kubectl-failure"
    case metricsUnavailable = "metrics-unavailable"
    case warningHeavy = "warning-heavy"
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
                expectedBehavior: "Overview shows OK with a top status row, four cards, and neutral Recent Warnings."
                    + " Pods tab groups watched Pods by namespace with ready counts.",
                limitations: "Requires visible menu inspection to confirm the top row, four-card grid, and capped warning area."
            )
        case .completedJobs:
            return makeFixture(
                id: state,
                display: evaluator.evaluate(snapshot: completedJobsSnapshot(), now: now),
                setupState: completedJobsSetupState(),
                expectedBehavior: "Overview shows OK when the watched scope has only completed Job Pods."
                    + " Pods tab has no active Pod rows and says completed jobs are OK.",
                limitations: "Requires visible menu inspection to confirm completed Job Pods do not appear as unready active rows."
            )
        case .watch:
            return makeFixture(
                id: state,
                display: evaluator.evaluate(snapshot: watchSnapshot(), now: now),
                expectedBehavior: "Overview shows Watch with a pinned BackOff warning row."
                    + " Hovering the top status explains the restarting qa-api Pod."
                    + " Pods tab shows the watched Pod first with yellow dot, 0/1, and gray issue text.",
                limitations: "Requires visible menu inspection to confirm reason-first warning copy, pinned marker, and card readability."
            )
        case .bad:
            return makeFixture(
                id: state,
                display: evaluator.evaluate(snapshot: badSnapshot(), now: now),
                expectedBehavior: "Overview shows Bad and prioritizes the broken tracked target in the top row."
                    + " Hovering the top status names the affected qa-payments Pods."
                    + " Pods tab shows failed Pods first with red dots and issue text.",
                limitations: "Requires visible menu inspection to confirm top-row priority and card state."
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
                expectedBehavior: "Overview shows Stale while preserving the last known top row and four cards with stale marking."
                    + " Hovering the top status explains the failed refresh reason.",
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
                expectedBehavior: "Overview shows Stale because the last successful refresh is too old and keeps cards visually stale.",
                limitations: "Requires visible menu inspection to confirm the stale banner is visible."
            )
        case .firstUse:
            return makeFixture(
                id: state,
                display: setupRequiredDisplay(reason: "No saved context yet."),
                setupState: firstUseSetupState(),
                isShowingSetup: true,
                expectedBehavior: "Menu opens the setup-required state before any saved context exists."
                    + " Short setup content stays near the top while the footer keeps clear spacing below it without forcing a tall menu.",
                limitations: "Requires visible menu inspection to confirm setup appears instead of a healthy menu, the footer does not hug short content, and the menu is not fixed to the long-content height."
            )
        case .emptyWatchlist:
            return makeFixture(
                id: state,
                display: setupRequiredDisplay(reason: "No watched namespace selected."),
                setupState: emptyWatchlistSetupState(),
                isShowingSetup: true,
                expectedBehavior: "Menu opens the setup-required state when the QA fixture context has no selected namespaces."
                    + " Short setup content stays near the top while the footer keeps clear spacing below it without forcing a tall menu.",
                limitations: "Requires visible menu inspection to confirm the empty watchlist action is visible, the footer does not hug short content, and the menu is not fixed to the long-content height."
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
        case .metricsUnavailable:
            return makeFixture(
                id: state,
                display: evaluator.evaluate(snapshot: metricsUnavailableSnapshot(), now: now),
                expectedBehavior: "Overview keeps OK cluster status while CPU and Memory cards show unavailable metrics."
                    + " Hovering the top status explains that metrics are unavailable."
                    + " Pods tab still shows watched Pods.",
                limitations: "Requires visible menu inspection to confirm unavailable metrics are distinct from normal current values."
            )
        case .warningHeavy:
            return makeFixture(
                id: state,
                display: evaluator.evaluate(snapshot: warningHeavySnapshot(), now: now),
                expectedBehavior: "Overview shows capped Recent Warnings with the pinned tracked warning first, repeat count visible, message secondary, and overflow left for Events."
                    + " Hovering the top status exposes the pinned tracked warning detail."
                    + " Events tab scrolls above the footer, the footer remains visible with refresh/settings/quit only, and Pods tab keeps attention rows before ready rows.",
                limitations: "Requires visible menu inspection to confirm warning rows stay clear, overflow keeps the footer reachable, the top row and four cards remain visible, and the tab bar has balanced spacing."
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
            nodeDetailsSection: .available(healthyNodeDetails()),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            podDetailsSection: .available(healthyPodDetails()),
            metricsSection: .available(metricsSummary()),
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

    private static func completedJobsSnapshot() -> ClusterSnapshot {
        ClusterSnapshot(
            contextName: "QA fixture",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            nodeDetailsSection: .available(healthyNodeDetails()),
            podsSection: .available(PodSummary(ready: 0, running: 0, total: 0)),
            podDetailsSection: .available([]),
            metricsSection: .available(metricsSummary()),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(
                    target: .namespace("qa-jobs"),
                    state: .ok,
                    reason: "completed jobs are OK"
                )
            ]),
            hasCompletedWatchedPods: true,
            capturedAt: capturedAt
        )
    }

    private static func watchSnapshot() -> ClusterSnapshot {
        ClusterSnapshot(
            contextName: "QA fixture",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            nodeDetailsSection: .available(healthyNodeDetails()),
            podsSection: .available(PodSummary(ready: 11, running: 11, total: 12)),
            podDetailsSection: .available(watchPodDetails()),
            metricsSection: .available(metricsSummary()),
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
            nodeDetailsSection: .available(badNodeDetails()),
            podsSection: .available(PodSummary(ready: 10, running: 10, total: 12)),
            podDetailsSection: .available(badPodDetails()),
            metricsSection: .available(metricsSummary()),
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

    private static func metricsUnavailableSnapshot() -> ClusterSnapshot {
        ClusterSnapshot(
            contextName: "QA fixture",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            nodeDetailsSection: .available(metricsUnavailableNodeDetails()),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            podDetailsSection: .available(healthyPodDetails()),
            metricsSection: .unavailable(reason: "metrics API unavailable"),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(
                    target: .namespace("qa-api"),
                    state: .ok,
                    reason: "6/6 watched pods running"
                )
            ]),
            capturedAt: capturedAt
        )
    }

    private static func warningHeavySnapshot() -> ClusterSnapshot {
        let trackedWarning = WarningEventRecord(
            reason: "BackOff",
            namespace: "qa-api",
            objectKind: "Pod",
            objectName: "qa-checkout-7f9",
            message: "Container is backing off after repeated restarts.",
            observedAt: Date(timeIntervalSince1970: 160),
            count: 2
        )

        return ClusterSnapshot(
            contextName: "QA fixture",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            nodeDetailsSection: .available(healthyNodeDetails()),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            podDetailsSection: .available(warningHeavyPodDetails()),
            metricsSection: .available(metricsSummary()),
            warningEventsSection: .available([
                WarningEventRecord(
                    reason: "FailedScheduling",
                    namespace: "qa-monitoring",
                    objectKind: "Pod",
                    objectName: "qa-metrics-0",
                    message: "Insufficient cpu.",
                    observedAt: Date(timeIntervalSince1970: 200),
                    count: 1
                ),
                trackedWarning,
                WarningEventRecord(
                    reason: "Unhealthy",
                    namespace: "qa-api",
                    objectKind: "Pod",
                    objectName: "qa-api-probe-0",
                    message: "Readiness probe failed.",
                    observedAt: Date(timeIntervalSince1970: 190),
                    count: 1
                )
            ]),
            workloadsSection: .available([
                TrackedItemStatus(
                    target: .namespace("qa-api"),
                    state: .watch,
                    reason: "latest warning: BackOff",
                    latestWarning: trackedWarning
                )
            ]),
            capturedAt: capturedAt
        )
    }

    private static func healthyNodeDetails() -> [NodeDetail] {
        [
            NodeDetail(
                name: "qa-worker-1",
                isReady: true,
                cpuUsageNanocores: 500_000_000,
                cpuAllocatableNanocores: 2_000_000_000,
                memoryUsageBytes: 1_073_741_824,
                memoryAllocatableBytes: 4_294_967_296
            ),
            NodeDetail(
                name: "qa-worker-2",
                isReady: true,
                cpuUsageNanocores: 750_000_000,
                cpuAllocatableNanocores: 3_000_000_000,
                memoryUsageBytes: 2_147_483_648,
                memoryAllocatableBytes: 8_589_934_592
            ),
            NodeDetail(
                name: "qa-worker-3",
                isReady: true,
                cpuUsageNanocores: 250_000_000,
                cpuAllocatableNanocores: 1_000_000_000,
                memoryUsageBytes: 536_870_912,
                memoryAllocatableBytes: 2_147_483_648
            )
        ]
    }

    private static func badNodeDetails() -> [NodeDetail] {
        [
            NodeDetail(
                name: "qa-worker-1",
                isReady: true,
                cpuUsageNanocores: 500_000_000,
                cpuAllocatableNanocores: 2_000_000_000,
                memoryUsageBytes: 1_073_741_824,
                memoryAllocatableBytes: 4_294_967_296
            ),
            NodeDetail(
                name: "qa-worker-2",
                isReady: false,
                issueReason: "KubeletNotReady",
                issueMessage: "container runtime is down",
                cpuUsageNanocores: 900_000_000,
                cpuAllocatableNanocores: 2_000_000_000,
                memoryUsageBytes: 3_221_225_472,
                memoryAllocatableBytes: 4_294_967_296
            ),
            NodeDetail(
                name: "qa-worker-3",
                isReady: true,
                cpuUsageNanocores: 250_000_000,
                cpuAllocatableNanocores: 1_000_000_000,
                memoryUsageBytes: 536_870_912,
                memoryAllocatableBytes: 2_147_483_648
            )
        ]
    }

    private static func metricsUnavailableNodeDetails() -> [NodeDetail] {
        [
            NodeDetail(name: "qa-worker-1", isReady: true),
            NodeDetail(name: "qa-worker-2", isReady: true),
            NodeDetail(name: "qa-worker-3", isReady: true)
        ]
    }

    private static func healthyPodDetails() -> [PodDetail] {
        [
            PodDetail(
                namespace: "qa-api",
                name: "qa-checkout-7f9",
                phase: "Running",
                readyContainerCount: 1,
                totalContainerCount: 1
            ),
            PodDetail(
                namespace: "qa-api",
                name: "qa-checkout-8a1",
                phase: "Running",
                readyContainerCount: 1,
                totalContainerCount: 1
            ),
            PodDetail(
                namespace: "qa-monitoring",
                name: "qa-prometheus-0",
                phase: "Running",
                readyContainerCount: 2,
                totalContainerCount: 2
            )
        ]
    }

    private static func watchPodDetails() -> [PodDetail] {
        [
            PodDetail(
                namespace: "qa-api",
                name: "qa-checkout-7f9",
                phase: "Running",
                readyContainerCount: 0,
                totalContainerCount: 1,
                notReadyConditionReason: "ContainersNotReady",
                notReadyConditionMessage: "containers with unready status",
                hasUnreadyContainer: true,
                isNotReady: true
            ),
            PodDetail(
                namespace: "qa-api",
                name: "qa-checkout-8a1",
                phase: "Running",
                readyContainerCount: 1,
                totalContainerCount: 1
            )
        ]
    }

    private static func badPodDetails() -> [PodDetail] {
        [
            PodDetail(
                namespace: "qa-payments",
                name: "qa-payments-api-0",
                phase: "Failed",
                readyContainerCount: 0,
                totalContainerCount: 1,
                terminatedReason: "Error",
                terminatedMessage: "container exited with code 1",
                hasUnreadyContainer: true,
                isFailed: true,
                isNotReady: true
            ),
            PodDetail(
                namespace: "qa-payments",
                name: "qa-payments-worker-1",
                phase: "Running",
                readyContainerCount: 0,
                totalContainerCount: 1,
                waitingReason: "CrashLoopBackOff",
                waitingMessage: "back-off restarting container",
                hasUnreadyContainer: true,
                isNotReady: true
            ),
            PodDetail(
                namespace: "qa-api",
                name: "qa-checkout-7f9",
                phase: "Running",
                readyContainerCount: 1,
                totalContainerCount: 1
            )
        ]
    }

    private static func warningHeavyPodDetails() -> [PodDetail] {
        [
            PodDetail(
                namespace: "qa-api",
                name: "qa-api-probe-0",
                phase: "Running",
                readyContainerCount: 0,
                totalContainerCount: 1,
                notReadyConditionReason: "ReadinessProbeFailed",
                notReadyConditionMessage: "readiness probe failed",
                hasUnreadyContainer: true,
                isNotReady: true
            ),
            PodDetail(
                namespace: "qa-api",
                name: "qa-checkout-7f9",
                phase: "Running",
                readyContainerCount: 1,
                totalContainerCount: 1
            ),
            PodDetail(
                namespace: "qa-monitoring",
                name: "qa-metrics-0",
                phase: "Pending",
                isPending: true,
                isNotReady: true
            )
        ]
    }

    private static func metricsSummary() -> ClusterMetricsSummary {
        ClusterMetricsSummary(
            cpuUsageNanocores: 750_000_000,
            cpuAllocatableNanocores: 3_500_000_000,
            memoryUsageBytes: 2_147_483_648,
            memoryAllocatableBytes: 12_884_901_888
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

    private static func completedJobsSetupState() -> SetupFlowState {
        SetupFlowState(
            selectedContext: "QA fixture",
            availableContexts: ["QA fixture", "QA standby"],
            watchlist: WatchlistSelectionState(
                availableNamespaces: ["qa-api", "qa-jobs", "qa-monitoring"],
                selectedTargets: [.namespace("qa-jobs")]
            ),
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
