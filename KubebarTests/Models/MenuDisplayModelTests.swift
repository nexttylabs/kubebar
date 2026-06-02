import Foundation
import Testing
@testable import KubebarCore

@Suite("Menu display model")
struct MenuDisplayModelTests {
    @Test("healthy snapshots show OK status and Overview cards")
    func healthySnapshotShowsOKStatusAndOverviewCards() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 12, total: 12),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "6/6 pods running")
            ],
            podDetailsSection: .available([
                podDetail(namespace: "api", name: "checkout-7f9d", readyContainerCount: 1, totalContainerCount: 1)
            ]),
            metricsSection: .available(metricsSummary()),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.state == .ok)
        #expect(display.contextName == "prod")
        #expect(display.counters.nodes == "3/3")
        #expect(display.counters.pods == "12/12")
        #expect(display.counters.warningEvents == "0")
        #expect(display.healthSentence == "All tracked items OK")
        #expect(display.primaryStatusReason == "All tracked items OK")
        #expect(display.overview.statusHelpText == "All tracked items OK")
        #expect(display.lastUpdated == "20s ago")
        #expect(display.overview.cards.map(\.id) == ["nodes", "pods", "cpu", "memory"])
        #expect(display.overview.cards.map(\.value) == ["3/3", "12/12", "21%", "17%"])
        #expect(display.overview.cards.allSatisfy { $0.state == .current })
        #expect(display.overview.cards.first(where: { $0.id == "cpu" })?.progress == 750_000_000.0 / 3_500_000_000.0)
        #expect(display.overview.cards.first(where: { $0.id == "memory" })?.progress == 2_147_483_648.0 / 12_884_901_888.0)
        #expect(display.overview.recentWarningsEmptyMessage == "No current warning events")
        #expect(display.nodeTab.summary == "3/3 nodes ready")
        #expect(display.nodeTab.emptyMessage == "No node data yet. Refresh or check Settings.")
        #expect(display.podTab.summary == "1/1 watched pods ready")
        #expect(display.podTab.sections.first?.namespace == "api")
        #expect(display.podTab.emptyMessage == "No pod data yet. Refresh or check Settings.")
        #expect(display.eventsTab.emptyMessage == "No current warning events")
    }

    @Test("display only freshness tick updates last checked")
    func displayOnlyFreshnessTickUpdatesLastChecked() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 12, total: 12),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "6/6 pods running")
            ],
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let initial = HealthEvaluator().evaluate(
            snapshot: snapshot,
            now: Date(timeIntervalSince1970: 100),
            staleAfterSeconds: 120
        )
        let tick = HealthEvaluator().evaluate(
            snapshot: snapshot,
            now: Date(timeIntervalSince1970: 101),
            staleAfterSeconds: 120
        )

        #expect(initial.state == .ok)
        #expect(initial.lastUpdated == "0s ago")
        #expect(tick.state == .ok)
        #expect(tick.lastUpdated == "1s ago")
        #expect(tick.counters == initial.counters)
        #expect(tick.visibleWatchItems == initial.visibleWatchItems)
    }

    @Test("bad tracked items become first-screen attention")
    func badTrackedItemsBecomeFirstScreenAttention() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 5, total: 6),
            warningEventCount: 1,
            trackedItems: [
                TrackedItemStatus(target: .workload(namespace: "api", name: "checkout"), state: .bad, reason: "1 pod pending"),
                TrackedItemStatus(target: .namespace("monitoring"), state: .ok, reason: "all watched pods running")
            ],
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.state == .bad)
        #expect(display.visibleWatchItems.first?.title == "api/checkout")
        #expect(display.visibleWatchItems.first?.reason == "1 pod pending")
        #expect(display.healthSentence == "api/checkout needs attention")
        #expect(display.primaryStatusReason == "1 pod pending")
    }

    @Test("watch and bad tracked targets expose k9s handoff target")
    func watchAndBadTrackedTargetsExposeK9sHandoff() {
        let watchSnapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 12, total: 12),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(
                    target: .namespace("api"),
                    state: .watch,
                    reason: "1 pod restarting"
                )
            ],
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let badSnapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 5, total: 6),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(
                    target: .workload(namespace: "api", name: "checkout"),
                    state: .bad,
                    reason: "1 pod unavailable"
                )
            ],
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let watchDisplay = HealthEvaluator().evaluate(snapshot: watchSnapshot, now: Date(timeIntervalSince1970: 120))
        let badDisplay = HealthEvaluator().evaluate(snapshot: badSnapshot, now: Date(timeIntervalSince1970: 120))

        #expect(watchDisplay.overview.k9sHandoff?.target.contextName == "prod")
        #expect(watchDisplay.overview.k9sHandoff?.target.namespace == "api")
        #expect(badDisplay.overview.k9sHandoff?.target.namespace == "api")
        #expect(watchDisplay.state == .watch)
        #expect(badDisplay.state == .bad)
    }

    @Test("healthy, stale, and warning-only states do not expose k9s handoff")
    func nonAbnormalTrackedStatesDoNotExposeK9sHandoff() {
        let healthySnapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 12, total: 12),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(
                    target: .namespace("api"),
                    state: .ok,
                    reason: "6/6 watched pods running"
                )
            ],
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let warningOnlySnapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([warningEvent(reason: "BackOff", observedAt: Date(timeIntervalSince1970: 100), count: 1)]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let staleSnapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 12, total: 12),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(
                    target: .namespace("api"),
                    state: .bad,
                    reason: "1 pod unavailable"
                )
            ],
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let healthyDisplay = HealthEvaluator().evaluate(snapshot: healthySnapshot, now: Date(timeIntervalSince1970: 120))
        let warningDisplay = HealthEvaluator().evaluate(
            snapshot: warningOnlySnapshot,
            now: Date(timeIntervalSince1970: 120)
        )
        let staleDisplay = HealthEvaluator().evaluate(
            snapshot: nil,
            previousSnapshot: staleSnapshot,
            failure: nil,
            now: Date(timeIntervalSince1970: 130),
            staleAfterSeconds: 10,
        )

        #expect(healthyDisplay.overview.k9sHandoff == nil)
        #expect(warningDisplay.overview.k9sHandoff == nil)
        #expect(staleDisplay.overview.k9sHandoff == nil)
    }

    @Test("list-level resources expose group-level k9s handoff targets")
    func listLevelResourcesExposeGroupLevelK9sHandoffTargets() throws {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 2, total: 3)),
            nodeDetailsSection: .available([
                nodeDetail(name: "worker-a", isReady: false, issueReason: "KubeletNotReady")
            ]),
            podsSection: .available(PodSummary(ready: 0, running: 1, total: 1)),
            podDetailsSection: .available([
                podDetail(
                    namespace: "api",
                    name: "checkout-7f9d",
                    readyContainerCount: 0,
                    totalContainerCount: 1,
                    waitingReason: "CrashLoopBackOff",
                    isNotReady: true
                )
            ]),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(
                    target: .workload(namespace: "api", name: "checkout", kind: .deployment),
                    state: .bad,
                    reason: "1 pod restarting"
                )
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let watchItem = try #require(display.visibleWatchItems.first)
        let podSection = try #require(display.podTab.sections.first)
        let podRow = try #require(podSection.rows.first)
        let nodeRow = try #require(display.nodeTab.rows.first)

        #expect(watchItem.k9sHandoff?.target.contextName == "prod")
        #expect(watchItem.k9sHandoff?.target.resource == .workload(namespace: "api", name: "checkout", kind: .deployment))
        #expect(podSection.k9sHandoff?.target.resource == .podList(namespace: "api"))
        #expect(podSection.k9sHandoff?.helpText == "Open api Pods in k9s")
        #expect(podSection.k9sHandoff?.accessibilityLabel == "Open api Pods in k9s")
        #expect(podRow.k9sHandoff == nil)
        #expect(display.nodeTab.k9sHandoff?.target.resource == .nodeList)
        #expect(display.nodeTab.k9sHandoff?.helpText == "Open Nodes in k9s")
        #expect(display.nodeTab.k9sHandoff?.accessibilityLabel == "Open Nodes in k9s")
        #expect(nodeRow.k9sHandoff == nil)
        #expect(display.k9sHandoffs.contains { $0.target.resource == .podList(namespace: "api") })
        #expect(display.k9sHandoffs.contains { $0.target.resource == .nodeList })
    }

    @Test("stale resource rows do not expose k9s handoff targets")
    func staleResourceRowsDoNotExposeK9sHandoffTargets() throws {
        let previous = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 2, total: 3)),
            nodeDetailsSection: .available([
                nodeDetail(name: "worker-a", isReady: false, issueReason: "KubeletNotReady")
            ]),
            podsSection: .available(PodSummary(ready: 0, running: 1, total: 1)),
            podDetailsSection: .available([
                podDetail(namespace: "api", name: "checkout-7f9d", readyContainerCount: 0, totalContainerCount: 1)
            ]),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(target: .namespace("api"), state: .bad, reason: "1 pod unavailable")
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(
            snapshot: nil,
            previousSnapshot: previous,
            failure: nil,
            now: Date(timeIntervalSince1970: 130),
            staleAfterSeconds: 10
        )
        let watchItem = try #require(display.visibleWatchItems.first)
        let podRow = try #require(display.podTab.sections.first?.rows.first)
        let nodeRow = try #require(display.nodeTab.rows.first)

        #expect(display.state == .stale)
        #expect(watchItem.k9sHandoff == nil)
        #expect(display.podTab.sections.first?.k9sHandoff == nil)
        #expect(podRow.k9sHandoff == nil)
        #expect(display.nodeTab.k9sHandoff == nil)
        #expect(nodeRow.k9sHandoff == nil)
    }

    @Test("tracked item status help includes expanded detail")
    func trackedItemStatusHelpIncludesExpandedDetail() {
        let latestWarning = warningEvent(
            reason: "BackOff",
            observedAt: Date(timeIntervalSince1970: 100),
            count: 2,
            message: "newest warning"
        )
        let item = TrackedItemStatus(
            target: .workload(namespace: "api", name: "checkout"),
            state: .bad,
            reason: "2 pods restarting",
            affectedPodCount: 2,
            examplePodNames: ["checkout-a", "checkout-b"],
            latestWarning: latestWarning
        )
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 10, total: 12)),
            metricsSection: .available(metricsSummary()),
            warningEventsSection: .available([]),
            workloadsSection: .available([item]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.overview.statusText == "2 pods restarting")
        #expect(display.overview.statusHelpText.contains("api/checkout: 2 pods restarting"))
        #expect(display.overview.statusHelpText.contains("2 affected pods"))
        #expect(display.overview.statusHelpText.contains("examples checkout-a, checkout-b"))
        #expect(display.overview.statusHelpText.contains("latest warning BackOff api/pod/checkout 2m ago x2, newest warning"))
        #expect(display.overview.statusAccessibilityLabel.contains(display.overview.statusHelpText))
    }

    @Test("warning events provide primary status reason")
    func warningEventsProvidePrimaryStatusReason() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(
                    reason: "BackOff",
                    observedAt: Date(timeIntervalSince1970: 100),
                    count: 2,
                    message: "newest warning"
                )
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.state == .watch)
        #expect(display.primaryStatusReason == "2 warning events")
        #expect(display.overview.statusHelpText == "BackOff api/pod/checkout 20s ago x2, newest warning")
    }

    @Test("single not ready node uses singular primary status reason")
    func singleNotReadyNodeUsesSingularPrimaryStatusReason() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 2, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.state == .bad)
        #expect(display.primaryStatusReason == "1 node not ready")
    }

    @Test("node status help includes node condition detail")
    func nodeStatusHelpIncludesNodeConditionDetail() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 2, total: 3)),
            nodeDetailsSection: .available([
                nodeDetail(
                    name: "worker-a",
                    isReady: false,
                    issueReason: "KubeletNotReady",
                    issueMessage: "container runtime is down"
                )
            ]),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            metricsSection: .available(metricsSummary()),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.primaryStatusReason == "1 node not ready")
        #expect(display.overview.statusHelpText == "worker-a, Not Ready, CPU 25%, Memory 25%, KubeletNotReady: container runtime is down")
        #expect(display.overview.statusAccessibilityLabel.contains("KubeletNotReady: container runtime is down"))
    }

    @Test("single not ready pod uses singular primary status reason")
    func singleNotReadyPodUsesSingularPrimaryStatusReason() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 11, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.state == .watch)
        #expect(display.primaryStatusReason == "1 pod not ready")
    }

    @Test("pod status help includes pod condition detail")
    func podStatusHelpIncludesPodConditionDetail() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(ready: 11, running: 12, total: 12)),
            podDetailsSection: .available([
                podDetail(
                    namespace: "api",
                    name: "checkout",
                    readyContainerCount: 0,
                    totalContainerCount: 1,
                    notReadyConditionReason: "ContainersNotReady",
                    notReadyConditionMessage: "containers with unready status",
                    isNotReady: true
                )
            ]),
            metricsSection: .available(metricsSummary()),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.primaryStatusReason == "1 pod not ready")
        #expect(display.overview.statusHelpText == "api/checkout, Watch, 0/1 containers ready, ContainersNotReady: containers with unready status, CPU usage unavailable, request unavailable, limit unavailable, Memory usage unavailable, request unavailable, limit unavailable")
        #expect(display.overview.statusAccessibilityLabel.contains("ContainersNotReady: containers with unready status"))
    }

    @Test("metrics unavailable does not change otherwise OK state")
    func metricsUnavailableDoesNotChangeOtherwiseOKState() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            metricsSection: .unavailable(reason: "metrics API unavailable"),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.state == .ok)
        #expect(display.primaryStatusReason == "Metrics unavailable")
        #expect(display.overview.statusHelpText == "Metrics unavailable: metrics API unavailable")
        #expect(display.overview.statusAccessibilityLabel.contains("metrics API unavailable"))
        #expect(display.overview.cards.first(where: { $0.id == "cpu" })?.state == .unavailable)
        #expect(display.overview.cards.first(where: { $0.id == "cpu" })?.progress == nil)
        #expect(display.overview.cards.first(where: { $0.id == "memory" })?.detail == "metrics API unavailable")
        #expect(display.overview.cards.first(where: { $0.id == "memory" })?.progress == nil)
    }

    @Test("node tab rows show sorted readiness and metrics")
    func nodeTabRowsShowSortedReadinessAndMetrics() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 2, total: 3)),
            nodeDetailsSection: .available([
                nodeDetail(name: "worker-z", isReady: true),
                nodeDetail(
                    name: "worker-a",
                    isReady: false,
                    issueReason: "KubeletNotReady",
                    issueMessage: "container runtime is down"
                ),
                nodeDetail(name: "worker-b", isReady: true, cpuUsageNanocores: nil, memoryUsageBytes: nil)
            ]),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let rows = display.nodeTab.rows

        #expect(rows.map(\.name) == ["worker-a", "worker-b", "worker-z"])
        #expect(rows[0].statusLabel == "Not Ready")
        #expect(rows[0].issueText == "KubeletNotReady: container runtime is down")
        #expect(rows[0].cpuLabel == "25%")
        #expect(rows[0].memoryLabel == "25%")
        #expect(rows[0].cpuProgress == 0.25)
        #expect(rows[0].memoryProgress == 0.25)
        #expect(rows[1].statusLabel == "Ready")
        #expect(rows[1].cpuLabel == "-")
        #expect(rows[1].memoryLabel == "-")
        #expect(rows[1].cpuProgress == nil)
        #expect(rows[1].memoryProgress == nil)
        #expect(rows[2].statusLabel == "Ready")
        #expect(rows[2].accessibilityLabel == "worker-z, Ready, CPU 25%, Memory 25%")
    }

    @Test("zero per node metrics remain visible as zero percent")
    func zeroPerNodeMetricsRemainVisibleAsZeroPercent() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 1, total: 1)),
            nodeDetailsSection: .available([
                nodeDetail(name: "worker-a", isReady: true, cpuUsageNanocores: 0, memoryUsageBytes: 0)
            ]),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let row = display.nodeTab.rows.first

        #expect(row?.cpuLabel == "0%")
        #expect(row?.memoryLabel == "0%")
        #expect(row?.cpuProgress == 0)
        #expect(row?.memoryProgress == 0)
    }

    @Test("node tab empty state uses an explicit display flag")
    func nodeTabEmptyStateUsesExplicitDisplayFlag() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 0, total: 0)),
            nodeDetailsSection: .available([]),
            podsSection: .available(PodSummary(running: 0, total: 0)),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.nodeTab.rows.isEmpty)
        #expect(display.nodeTab.showsEmptyMessage == true)
    }

    @Test("overview pods use ready count while pod tab keeps running count")
    func overviewPodsUseReadyCountWhilePodTabKeepsRunningCount() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(ready: 10, running: 12, total: 12)),
            metricsSection: .available(metricsSummary()),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.state == .watch)
        #expect(display.primaryStatusReason == "2 pods not ready")
        #expect(display.overview.cards.first(where: { $0.id == "pods" })?.value == "10/12")
        #expect(display.podTab.summary == "12/12 pods running")
    }

    @Test("pod tab groups rows by namespace and attention")
    func podTabGroupsRowsByNamespaceAndAttention() throws {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(ready: 3, running: 4, total: 4)),
            podDetailsSection: .available([
                podDetail(namespace: "monitoring", name: "prometheus-0", readyContainerCount: 2, totalContainerCount: 2),
                podDetail(namespace: "api", name: "checkout-ready", readyContainerCount: 1, totalContainerCount: 1),
                podDetail(
                    namespace: "api",
                    name: "checkout-crash",
                    readyContainerCount: 0,
                    totalContainerCount: 1,
                    waitingReason: "CrashLoopBackOff",
                    waitingMessage: "back-off restarting container",
                    isNotReady: true
                ),
                podDetail(
                    namespace: "api",
                    name: "checkout-pending",
                    phase: "Pending",
                    isPending: true,
                    isNotReady: true
                )
            ]),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(target: .namespace("api"), state: .bad, reason: "1 pod restarting"),
                TrackedItemStatus(target: .namespace("monitoring"), state: .ok, reason: "1/1 pods running")
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let sections = display.podTab.sections
        let apiRows = try #require(sections.first?.rows)

        #expect(display.podTab.summary == "2/4 watched pods ready")
        #expect(sections.map(\.namespace) == ["api", "monitoring"])
        #expect(apiRows.map(\.name) == ["checkout-crash", "checkout-pending", "checkout-ready"])
        #expect(apiRows.map(\.state) == [.bad, .watch, .ready])
        #expect(apiRows[0].readyLabel == "0/1")
        #expect(apiRows[0].issueText == "CrashLoopBackOff: back-off restarting container")
        #expect(apiRows[0].accessibilityLabel.contains("Bad") == true)
        #expect(apiRows[1].readyLabel == "-")
        #expect(apiRows[1].issueText == "Pending")
        #expect(apiRows[2].issueText == nil)
    }

    @Test("pod rows include resource summary labels")
    func podRowsIncludeResourceSummaryLabels() throws {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 2, total: 2)),
            podDetailsSection: .available([
                podDetail(
                    namespace: "api",
                    name: "checkout-7f9d",
                    readyContainerCount: 1,
                    totalContainerCount: 1,
                    resourceSummary: PodResourceSummary(
                        cpuUsageNanocores: 500_000_000,
                        cpuRequestNanocores: 1_000_000_000,
                        cpuLimitNanocores: 2_000_000_000,
                        memoryUsageBytes: 1_073_741_824,
                        memoryRequestBytes: 2_147_483_648,
                        memoryLimitBytes: 4_294_967_296
                    )
                )
            ]),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(target: .namespace("api"), state: .ok, reason: "1/1 pods running")
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let row = try #require(display.podTab.sections.first?.rows.first)

        #expect(row.resourceLabel == "CPU 50% of request · Memory 25% of limit")
        #expect(row.helpText.contains("CPU usage 0.5 cores, request 1 core, limit 2 cores"))
        #expect(row.helpText.contains("Memory usage 1GiB, request 2GiB, limit 4GiB"))
        #expect(row.cpuProgress == 0.5)
        #expect(row.memoryProgress == 0.25)
    }

    @Test("pod rows show resource summary when usage is missing")
    func podRowsShowResourceSummaryWhenUsageIsMissing() throws {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 1, total: 1)),
            podDetailsSection: .available([
                podDetail(
                    namespace: "api",
                    name: "checkout-7f9d",
                    readyContainerCount: 1,
                    totalContainerCount: 1,
                    resourceSummary: PodResourceSummary(
                        cpuUsageNanocores: nil,
                        cpuRequestNanocores: 1_000_000_000,
                        cpuLimitNanocores: 2_000_000_000,
                        memoryUsageBytes: nil,
                        memoryRequestBytes: 2_147_483_648,
                        memoryLimitBytes: nil
                    )
                )
            ]),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(target: .namespace("api"), state: .ok, reason: "1/1 pods running")
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let row = try #require(display.podTab.sections.first?.rows.first)

        #expect(row.resourceLabel == "CPU - · Memory -")
        #expect(row.cpuProgress == nil)
        #expect(row.memoryProgress == nil)
        #expect(row.helpText.contains("CPU usage unavailable, request 1 core, limit 2 cores"))
        #expect(row.helpText.contains("Memory usage unavailable, request 2GiB, limit unavailable"))
        #expect(!row.helpText.contains("-/"))
        #expect(row.accessibilityLabel == row.helpText)
    }

    @Test("pod rows use fallback basis and raw resource labels")
    func podRowsUseFallbackBasisAndRawResourceLabels() throws {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 2, total: 2)),
            podDetailsSection: .available([
                podDetail(
                    namespace: "api",
                    name: "fallback-basis",
                    readyContainerCount: 1,
                    totalContainerCount: 1,
                    resourceSummary: PodResourceSummary(
                        cpuUsageNanocores: 250_000_000,
                        cpuRequestNanocores: nil,
                        cpuLimitNanocores: 1_000_000_000,
                        memoryUsageBytes: 268_435_456,
                        memoryRequestBytes: 536_870_912,
                        memoryLimitBytes: nil
                    )
                ),
                podDetail(
                    namespace: "api",
                    name: "raw-only",
                    readyContainerCount: 1,
                    totalContainerCount: 1,
                    resourceSummary: PodResourceSummary(
                        cpuUsageNanocores: 120_000_000,
                        memoryUsageBytes: 268_435_456
                    )
                )
            ]),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(target: .namespace("api"), state: .ok, reason: "2/2 pods running")
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let rows = try #require(display.podTab.sections.first?.rows)
        let fallback = try #require(rows.first { $0.name == "fallback-basis" })
        let rawOnly = try #require(rows.first { $0.name == "raw-only" })

        #expect(fallback.resourceLabel == "CPU 25% of limit · Memory 50% of request")
        #expect(fallback.cpuProgress == 0.25)
        #expect(fallback.memoryProgress == 0.5)
        #expect(rawOnly.resourceLabel == "CPU 120m · Memory 256Mi")
        #expect(rawOnly.cpuProgress == nil)
        #expect(rawOnly.memoryProgress == nil)
    }

    @Test("pod progress can exceed selected resource basis")
    func podProgressCanExceedSelectedResourceBasis() throws {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 1, total: 1)),
            podDetailsSection: .available([
                podDetail(
                    namespace: "api",
                    name: "hot-pod",
                    readyContainerCount: 1,
                    totalContainerCount: 1,
                    resourceSummary: PodResourceSummary(
                        cpuUsageNanocores: 2_000_000_000,
                        cpuRequestNanocores: 1_000_000_000,
                        memoryUsageBytes: 6_442_450_944,
                        memoryLimitBytes: 4_294_967_296
                    )
                )
            ]),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(target: .namespace("api"), state: .ok, reason: "1/1 pods running")
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let row = try #require(display.podTab.sections.first?.rows.first)

        #expect(row.resourceLabel == "CPU 200% of request · Memory 150% of limit")
        #expect(row.cpuProgress == 2)
        #expect(row.memoryProgress == 1.5)
        #expect(display.state == .ok)
    }

    @Test("pod row help keeps resource markers when all values are unavailable")
    func podRowHelpKeepsResourceMarkersWhenAllValuesAreUnavailable() throws {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 1, total: 1)),
            podDetailsSection: .available([
                podDetail(
                    namespace: "api",
                    name: "checkout-7f9d",
                    readyContainerCount: 1,
                    totalContainerCount: 1
                )
            ]),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(target: .namespace("api"), state: .ok, reason: "1/1 pods running")
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let row = try #require(display.podTab.sections.first?.rows.first)

        #expect(row.resourceLabel == "CPU - · Memory -")
        #expect(row.helpText == "api/checkout-7f9d, Ready, 1/1 containers ready, CPU usage unavailable, request unavailable, limit unavailable, Memory usage unavailable, request unavailable, limit unavailable")
        #expect(row.accessibilityLabel == row.helpText)
    }

    @Test("pod rows can show issue and resource summary together")
    func podRowsCanShowIssueAndResourceSummaryTogether() throws {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 1, total: 1)),
            podDetailsSection: .available([
                podDetail(
                    namespace: "api",
                    name: "checkout-7f9d",
                    readyContainerCount: 1,
                    totalContainerCount: 1,
                    waitingReason: "CrashLoopBackOff",
                    waitingMessage: "back-off restarting container",
                    resourceSummary: PodResourceSummary(
                        cpuUsageNanocores: 250_000_000,
                        cpuRequestNanocores: 500_000_000,
                        cpuLimitNanocores: 1_000_000_000,
                        memoryUsageBytes: 268_435_456,
                        memoryRequestBytes: 536_870_912,
                        memoryLimitBytes: 1_073_741_824
                    )
                )
            ]),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(target: .namespace("api"), state: .bad, reason: "1 pod restarting")
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let row = try #require(display.podTab.sections.first?.rows.first)

        #expect(row.state == .bad)
        #expect(row.issueText == "CrashLoopBackOff: back-off restarting container")
        #expect(row.resourceLabel == "CPU 50% of request · Memory 25% of limit")
        #expect(row.cpuProgress == 0.5)
        #expect(row.memoryProgress == 0.25)
        let issueRange = try #require(row.helpText.range(of: "CrashLoopBackOff: back-off restarting container"))
        let resourceRange = try #require(row.helpText.range(of: "CPU usage 0.3 cores, request 0.5 cores, limit 1 core"))
        #expect(issueRange.lowerBound < resourceRange.lowerBound)
    }

    @Test("pod tab does not mark historical restarts as bad")
    func podTabDoesNotMarkHistoricalRestartsAsBad() throws {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(ready: 1, running: 1, total: 1)),
            podDetailsSection: .available([
                podDetail(namespace: "api", name: "checkout", readyContainerCount: 1, totalContainerCount: 1)
            ]),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(target: .namespace("api"), state: .ok, reason: "1/1 pods running")
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let row = try #require(display.podTab.sections.first?.rows.first)

        #expect(row.state == .ready)
        #expect(row.issueText == nil)
    }

    @Test("pod tab treats empty watched pods as healthy and distinct from unavailable")
    func podTabTreatsEmptyWatchedPodsAsHealthyAndDistinctFromUnavailable() {
        let unavailable = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .unavailable(reason: "invalid pod JSON"),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let empty = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(ready: 0, running: 0, total: 0)),
            podDetailsSection: .available([]),
            metricsSection: .available(metricsSummary()),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(target: .namespace("api"), state: .ok, reason: "no matching pods")
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let unavailableDisplay = HealthEvaluator().evaluate(snapshot: unavailable, now: Date(timeIntervalSince1970: 120))
        let emptyDisplay = HealthEvaluator().evaluate(snapshot: empty, now: Date(timeIntervalSince1970: 120))

        #expect(unavailableDisplay.podTab.unavailableMessage == "Pod data unavailable: invalid pod JSON")
        #expect(emptyDisplay.state == .ok)
        #expect(emptyDisplay.primaryStatusReason == "All tracked items OK")
        #expect(emptyDisplay.visibleWatchItems.first?.state == .ok)
        #expect(emptyDisplay.visibleWatchItems.first?.reason == "no matching pods")
        #expect(emptyDisplay.podTab.unavailableMessage == nil)
        #expect(emptyDisplay.podTab.sections.isEmpty)
        #expect(emptyDisplay.podTab.emptyMessage == "No watched pods found")
    }

    @Test("completed only watched pods stay healthy with completed empty message")
    func completedOnlyWatchedPodsStayHealthyWithCompletedEmptyMessage() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(ready: 0, running: 0, total: 0)),
            podDetailsSection: .available([]),
            metricsSection: .available(metricsSummary()),
            warningEventsSection: .available([]),
            workloadsSection: .available([
                TrackedItemStatus(target: .namespace("jobs"), state: .ok, reason: "completed jobs are OK")
            ]),
            hasCompletedWatchedPods: true,
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.state == .ok)
        #expect(display.primaryStatusReason == "All tracked items OK")
        #expect(display.podTab.sections.isEmpty)
        #expect(display.podTab.emptyMessage == "No active pods; completed jobs are OK")
    }

    @Test("single warning event uses singular primary status reason")
    func singleWarningEventUsesSingularPrimaryStatusReason() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(reason: "BackOff", observedAt: Date(timeIntervalSince1970: 100), count: 1)
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.state == .watch)
        #expect(display.primaryStatusReason == "1 warning event")
    }

    @Test("healthy first screen caps watchlist at three and reports overflow")
    func healthyFirstScreenCapsWatchlistAtThreeAndReportsOverflow() {
        let items = (1...7).map { index in
            TrackedItemStatus(target: .workload(namespace: "team", name: "service-\(index)"), state: .ok, reason: "ready")
        }
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 20, total: 20),
            warningEventCount: 0,
            trackedItems: items,
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.visibleWatchItems.count == 3)
        #expect(display.hiddenWatchItemCount == 4)
    }

    @Test("attention watchlist is ranked bad watch stale ok and can show five")
    func attentionWatchlistIsRankedBadWatchStaleOKAndCanShowFive() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 18, total: 20),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(target: .workload(namespace: "team", name: "ok-b"), state: .ok, reason: "ready"),
                TrackedItemStatus(target: .workload(namespace: "team", name: "stale-a"), state: .stale, reason: "No recent data"),
                TrackedItemStatus(target: .workload(namespace: "team", name: "bad-b"), state: .bad, reason: "2 pods failed"),
                TrackedItemStatus(target: .workload(namespace: "team", name: "watch-a"), state: .watch, reason: "1 pod restarting"),
                TrackedItemStatus(target: .workload(namespace: "team", name: "bad-a"), state: .bad, reason: "3 pods pending"),
                TrackedItemStatus(target: .workload(namespace: "team", name: "ok-a"), state: .ok, reason: "ready")
            ],
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.visibleWatchItems.map(\.title) == [
            "team/bad-a",
            "team/bad-b",
            "team/watch-a",
            "team/stale-a",
            "team/ok-a"
        ])
        #expect(display.alertWatchItems.map(\.title) == [
            "team/bad-a",
            "team/bad-b",
            "team/watch-a",
            "team/stale-a",
            "team/ok-a",
            "team/ok-b"
        ])
        #expect(display.hiddenWatchItemCount == 1)
    }

    @Test("long watch item titles stay full for middle truncation")
    func longWatchItemTitlesStayFullForMiddleTruncation() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 1, total: 1),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(
                    target: .workload(namespace: "production-namespace", name: "checkout-api-with-a-very-long-name"),
                    state: .ok,
                    reason: "ready"
                )
            ],
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.visibleWatchItems.first?.title == "production-namespace/checkout-api-with-a-very-long-name")
    }

    @Test("similar long watch item titles keep suffix differences")
    func similarLongWatchItemTitlesKeepSuffixDifferences() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 2, total: 2),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(
                    target: .workload(namespace: "production-namespace", name: "checkout-api-with-shared-long-prefix-api"),
                    state: .ok,
                    reason: "ready"
                ),
                TrackedItemStatus(
                    target: .workload(namespace: "production-namespace", name: "checkout-worker-with-shared-long-prefix-worker"),
                    state: .ok,
                    reason: "ready"
                )
            ],
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
        let titles = display.visibleWatchItems.map(\.title)

        #expect(titles == [
            "production-namespace/checkout-api-with-shared-long-prefix-api",
            "production-namespace/checkout-worker-with-shared-long-prefix-worker"
        ])
    }

    @Test("failed refresh keeps previous data but marks it stale")
    func failedRefreshKeepsPreviousDataButMarksItStale() {
        let previous = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 12, total: 12),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "6/6 pods running")
            ],
            podDetailsSection: .available([
                podDetail(namespace: "api", name: "checkout-7f9d", readyContainerCount: 1, totalContainerCount: 1)
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(
            snapshot: nil,
            previousSnapshot: previous,
            failure: RefreshFailure(reason: "kubectl timed out"),
            now: Date(timeIntervalSince1970: 250)
        )

        #expect(display.state == .stale)
        #expect(display.contextName == "prod")
        #expect(display.lastUpdated == "2m ago")
        #expect(display.staleBanner?.lastUpdated == "2m ago")
        #expect(display.staleBanner?.reason == "kubectl timed out")
        #expect(display.primaryStatusReason == "kubectl timed out")
        #expect(display.overview.statusHelpText == "kubectl timed out, last updated 2m ago")
        #expect(display.overview.statusAccessibilityLabel.contains("kubectl timed out, last updated 2m ago"))
        #expect(display.visibleWatchItems.first?.title == "api/checkout")
    }

    @Test("old healthy snapshot becomes stale after freshness window")
    func oldHealthySnapshotBecomesStaleAfterFreshnessWindow() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 12, total: 12),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "6/6 pods running")
            ],
            podDetailsSection: .available([
                podDetail(namespace: "api", name: "checkout-7f9d", readyContainerCount: 1, totalContainerCount: 1)
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(
            snapshot: snapshot,
            now: Date(timeIntervalSince1970: 221),
            staleAfterSeconds: 120
        )

        #expect(display.state == .stale)
        #expect(display.contextName == "prod")
        #expect(display.counters.nodes == "3/3")
        #expect(display.visibleWatchItems.first?.title == "api/checkout")
        #expect(display.lastUpdated == "2m ago")
        #expect(display.staleBanner?.reason == "Last refresh is too old")
        #expect(display.primaryStatusReason == "Last refresh is too old")
        #expect(display.overview.statusHelpText == "Last refresh is too old, last updated 2m ago")
    }

    @Test("watch item detail defaults to row reason")
    func watchItemDetailDefaultsToRowReason() {
        let item = WatchItemDisplay(
            id: "api/checkout",
            title: "api/checkout",
            state: .watch,
            reason: "1 pod not ready"
        )

        #expect(item.detail.reason == "1 pod not ready")
        #expect(item.detail.hasExpandedContent == false)
    }

    @Test("watch item detail reports expanded content only when extra detail exists")
    func watchItemDetailReportsExpandedContentOnlyWhenExtraDetailExists() {
        let warning = WarningEventDisplay(
            id: "warning",
            reason: "BackOff",
            location: "api/pod/checkout",
            age: "2m ago",
            occurrenceCount: 1,
            message: nil
        )

        #expect(WatchItemDetailDisplay(stateLabel: "OK", reason: "ready").hasExpandedContent == false)
        #expect(WatchItemDetailDisplay(stateLabel: "Bad", reason: "2 pods failed", affectedPodCount: 2).hasExpandedContent)
        #expect(WatchItemDetailDisplay(stateLabel: "Bad", reason: "2 pods failed", examplePodNames: ["checkout-a"]).hasExpandedContent)
        #expect(WatchItemDetailDisplay(stateLabel: "Watch", reason: "BackOff", latestWarning: warning).hasExpandedContent)
    }

    @Test("pod item display keeps legacy resource progress compatibility")
    func podItemDisplayKeepsLegacyResourceProgressCompatibility() {
        let split = PodItemDisplay(
            namespace: "api",
            name: "checkout",
            state: .ready,
            readyLabel: "1/1",
            resourceLabel: "CPU 40% of request · Memory 70% of limit",
            cpuProgress: 0.4,
            memoryProgress: 0.7,
            helpText: "api/checkout",
            accessibilityLabel: "api/checkout"
        )
        let legacy = PodItemDisplay(
            namespace: "api",
            name: "checkout",
            state: .ready,
            readyLabel: "1/1",
            resourceLabel: "CPU 60% of request · Memory 60% of limit",
            resourceProgress: 0.6,
            helpText: "api/checkout",
            accessibilityLabel: "api/checkout"
        )

        #expect(split.resourceProgress == 0.7)
        #expect(legacy.cpuProgress == 0.6)
        #expect(legacy.memoryProgress == 0.6)
        #expect(legacy.resourceProgress == 0.6)
    }

    @Test("warning event display summary includes occurrence count only when repeated")
    func warningEventDisplaySummaryIncludesOccurrenceCountOnlyWhenRepeated() {
        let single = WarningEventDisplay(
            id: "single",
            reason: "BackOff",
            location: "api/pod/checkout",
            age: "2m ago",
            occurrenceCount: 1,
            message: nil
        )
        let repeated = WarningEventDisplay(
            id: "repeated",
            reason: "BackOff",
            location: "api/pod/checkout",
            age: "2m ago",
            occurrenceCount: 4,
            message: nil
        )

        #expect(single.summary == "BackOff api/pod/checkout 2m ago")
        #expect(single.metadataLabel == "2m ago")
        #expect(single.secondaryText == "api/pod/checkout")
        #expect(single.accessibilityLabel == "Warning, BackOff, object api/pod/checkout, 2m ago")
        #expect(repeated.summary == "BackOff api/pod/checkout 2m ago x4")
        #expect(repeated.metadataLabel == "2m ago / x4")
        #expect(repeated.accessibilityLabel == "Warning, BackOff, object api/pod/checkout, 2m ago, repeated 4 times")
    }

    @Test("warning event display keeps message secondary and accessibility complete")
    func warningEventDisplayKeepsMessageSecondaryAndAccessibilityComplete() {
        let warning = WarningEventDisplay(
            id: "tracked",
            reason: "FailedScheduling",
            location: "api/pod/checkout",
            age: "30s ago",
            occurrenceCount: 2,
            message: "Insufficient cpu.",
            fullMessage: "Insufficient cpu on every available node.",
            isTracked: true
        )

        #expect(warning.summary == "FailedScheduling api/pod/checkout 30s ago x2")
        #expect(warning.metadataLabel == "30s ago / x2")
        #expect(warning.secondaryText == "api/pod/checkout - Insufficient cpu.")
        #expect(warning.helpText == "FailedScheduling api/pod/checkout 30s ago x2, Insufficient cpu on every available node.")
        #expect(warning.accessibilityLabel == "Tracked object warning, FailedScheduling, object api/pod/checkout, 30s ago, repeated 2 times, Insufficient cpu on every available node.")
    }

    @Test("duplicate warning events group into one warning summaries row")
    func duplicateWarningEventsGroupIntoOneWarningSummaryRow() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(reason: "BackOff", observedAt: Date(timeIntervalSince1970: 90), count: 1, message: "older warning"),
                warningEvent(reason: "BackOff", observedAt: Date(timeIntervalSince1970: 100), count: 3, message: "newest warning")
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.warningEventSummaries.count == 1)
        #expect(display.warningEventSummaries.first?.occurrenceCount == 4)
        #expect(display.warningEventSummaries.first?.summary == "BackOff api/pod/checkout 2m ago x4")
        #expect(display.warningEventSummaries.first?.message == "newest warning")
        #expect(display.warningEventSummaries.first?.secondaryText == "api/pod/checkout - newest warning")
    }

    @Test("warning summaries are capped at three rows")
    func warningSummariesAreCappedAtThreeRows() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(reason: "BackOff", objectName: "checkout-a", observedAt: Date(timeIntervalSince1970: 100), count: 1),
                warningEvent(reason: "FailedScheduling", objectName: "checkout-b", observedAt: Date(timeIntervalSince1970: 90), count: 1),
                warningEvent(reason: "Unhealthy", objectName: "checkout-c", observedAt: Date(timeIntervalSince1970: 80), count: 1),
                warningEvent(reason: "Pulled", objectName: "checkout-d", observedAt: Date(timeIntervalSince1970: 70), count: 1)
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.warningEventSummaries.count == 3)
    }

    @Test("warning rows keep stable fallback object scope")
    func warningRowsKeepStableFallbackObjectScope() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(
                    reason: "BackOff",
                    namespace: nil,
                    objectKind: nil,
                    objectName: nil,
                    observedAt: Date(timeIntervalSince1970: 100),
                    count: 1
                )
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.warningEventSummaries.first?.location == "unknown object")
        #expect(display.warningEventSummaries.first?.secondaryText == "unknown object")
    }

    @Test("overview warning rows are capped and tracked warnings are first")
    func overviewWarningRowsAreCappedAndTrackedWarningsAreFirst() {
        let trackedWarning = warningEvent(reason: "BackOff", objectName: "checkout-a", observedAt: Date(timeIntervalSince1970: 80), count: 1)
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            metricsSection: .available(metricsSummary()),
            warningEventsSection: .available([
                warningEvent(reason: "FailedScheduling", objectName: "checkout-b", observedAt: Date(timeIntervalSince1970: 120), count: 1),
                trackedWarning,
                warningEvent(reason: "Unhealthy", objectName: "checkout-c", observedAt: Date(timeIntervalSince1970: 100), count: 1)
            ]),
            workloadsSection: .available([
                TrackedItemStatus(
                    target: .workload(namespace: "api", name: "checkout"),
                    state: .watch,
                    reason: "latest warning: BackOff",
                    latestWarning: trackedWarning
                )
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.overview.recentWarnings.count == 2)
        #expect(display.overview.recentWarnings.first?.reason == "BackOff")
        #expect(display.overview.recentWarnings.first?.isTracked == true)
        #expect(display.overview.recentWarnings.dropFirst().first?.isTracked == false)
        #expect(display.overview.recentWarningsOverflowCount == 1)
    }

    @Test("overview warning overflow counts grouped rows")
    func overviewWarningOverflowCountsGroupedRows() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            metricsSection: .available(metricsSummary()),
            warningEventsSection: .available([
                warningEvent(reason: "BackOff", objectName: "checkout-a", observedAt: Date(timeIntervalSince1970: 120), count: 1),
                warningEvent(reason: "BackOff", objectName: "checkout-a", observedAt: Date(timeIntervalSince1970: 110), count: 1),
                warningEvent(reason: "FailedScheduling", objectName: "checkout-b", observedAt: Date(timeIntervalSince1970: 100), count: 1)
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.overview.recentWarnings.count == 2)
        #expect(display.overview.recentWarningsOverflowCount == 0)
    }

    @Test("long warning message is shortened before display")
    func longWarningMessageIsShortenedBeforeDisplay() {
        let longWarning = String(repeating: "a", count: 140)
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(reason: "BackOff", observedAt: Date(timeIntervalSince1970: 100), count: 1, message: longWarning)
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.warningEventSummaries.first?.message?.count == 96)
        #expect(display.warningEventSummaries.first?.message?.hasSuffix("...") == true)
        #expect(display.warningEventSummaries.first?.message != longWarning)
        #expect(display.warningEventSummaries.first?.fullMessage == longWarning)
        #expect(display.warningEventSummaries.first?.accessibilityLabel.contains(longWarning) == true)
    }

    @Test("tracked item detail.examplePodNames are capped at three")
    func trackedItemDetailExamplePodNamesAreCappedAtThree() {
        let item = TrackedItemStatus(
            target: .workload(namespace: "api", name: "checkout"),
            state: .bad,
            reason: "5 pods restarting",
            affectedPodCount: 5,
            examplePodNames: ["checkout-a", "checkout-b", "checkout-c", "checkout-d", "checkout-e"]
        )
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 7, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .available([item]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.visibleWatchItems.first?.detail.examplePodNames == ["checkout-a", "checkout-b", "checkout-c"])
        #expect(display.podTab.rows.first?.detail.examplePodNames == ["checkout-a", "checkout-b", "checkout-c"])
    }

    @Test("tracked item detail includes affected pod count and latest warning")
    func trackedItemDetailIncludesAffectedPodCountAndLatestWarning() {
        let latestWarning = warningEvent(reason: "BackOff", observedAt: Date(timeIntervalSince1970: 100), count: 2, message: "newest warning")
        let item = TrackedItemStatus(
            target: .workload(namespace: "api", name: "checkout"),
            state: .bad,
            reason: "2 pods restarting",
            affectedPodCount: 2,
            examplePodNames: ["checkout-a", "checkout-b"],
            latestWarning: latestWarning
        )
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 10, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .available([item]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.visibleWatchItems.first?.detail.affectedPodCount == 2)
        #expect(display.visibleWatchItems.first?.detail.latestWarning?.reason == "BackOff")
        #expect(display.visibleWatchItems.first?.detail.latestWarning?.occurrenceCount == 2)
    }

    @Test("unavailable warning events use dash counter and watch state")
    func unavailableWarningEventsUseDashCounterAndWatchState() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .unavailable(reason: "invalid event JSON"),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.counters.warningEvents == "-")
        #expect(display.state == .watch)
        #expect(display.primaryStatusReason == "invalid event JSON")
        #expect(display.overview.statusHelpText == "Warning events unavailable: invalid event JSON")
        #expect(display.sectionNotices.contains { $0.title == "Warning events" && $0.reason == "invalid event JSON" })
        #expect(display.overview.recentWarningsUnavailableMessage == "Warning events unavailable: invalid event JSON")
        #expect(display.overview.recentWarningsEmptyMessage == "Warning event count unavailable")
        #expect(display.eventsTab.unavailableMessage == "Warning events unavailable: invalid event JSON")
    }

    @Test("missing warning event count does not look empty")
    func missingWarningEventCountDoesNotLookEmpty() {
        let display = HealthEvaluator().evaluate(
            snapshot: nil,
            failure: RefreshFailure(reason: "Waiting for first refresh"),
            now: Date(timeIntervalSince1970: 220)
        )

        #expect(display.counters.warningEvents == "-")
        #expect(display.overview.recentWarningsEmptyMessage == "Warning event count unavailable")
        #expect(display.eventsTab.emptyMessage == "Warning event count unavailable")
    }

    @Test("unavailable pods use dash counter")
    func unavailablePodsUseDashCounter() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .unavailable(reason: "invalid pod JSON"),
            warningEventsSection: .available([]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.counters.pods == "-")
        #expect(display.state == .watch)
        #expect(display.podTab.unavailableMessage == "Pod data unavailable: invalid pod JSON")
    }

    @Test("pods tab surfaces workload section failures")
    func podsTabSurfacesWorkloadSectionFailures() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .unavailable(reason: "invalid workload JSON"),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.podTab.summary == "12/12 pods running")
        #expect(display.podTab.rows.isEmpty)
        #expect(display.podTab.unavailableMessage == "Workloads unavailable: invalid workload JSON")
    }

    @Test("tab unavailable copy uses safe section reasons")
    func tabUnavailableCopyUsesSafeSectionReasons() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .unavailable(reason: "invalid node JSON"),
            podsSection: .unavailable(reason: "invalid pod JSON"),
            warningEventsSection: .unavailable(reason: "invalid event JSON"),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.nodeTab.unavailableMessage == "Node data unavailable: invalid node JSON")
        #expect(display.podTab.unavailableMessage == "Pod data unavailable: invalid pod JSON")
        #expect(display.eventsTab.unavailableMessage == "Warning events unavailable: invalid event JSON")
    }

    @Test("stale tab display preserves previous counters watchlist and stale banner")
    func staleTabDisplayPreservesPreviousCountersWatchlistAndStaleBanner() {
        let previous = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 12, total: 12),
            warningEventCount: 0,
            trackedItems: [
                TrackedItemStatus(target: .workload(namespace: "api", name: "checkout"), state: .ok, reason: "6/6 pods running")
            ],
            podDetailsSection: .available([
                podDetail(namespace: "api", name: "checkout-7f9d", readyContainerCount: 1, totalContainerCount: 1)
            ]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(
            snapshot: nil,
            previousSnapshot: previous,
            failure: RefreshFailure(reason: "kubectl timed out"),
            now: Date(timeIntervalSince1970: 250)
        )

        #expect(display.counters.nodes == "3/3")
        #expect(display.nodeTab.summary == "3/3 nodes ready")
        #expect(display.podTab.summary == "1/1 watched pods ready")
        #expect(display.podTab.rows.first?.title == "api/checkout")
        #expect(display.podTab.sections.first?.rows.first?.name == "checkout-7f9d")
        #expect(display.eventsTab.emptyMessage == "No current warning events")
        #expect(display.staleBanner?.reason == "kubectl timed out")
    }

    @Test("overview notice is capped at one and prefers unavailable sections")
    func overviewNoticeIsCappedAtOneAndPrefersUnavailableSections() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(reason: "BackOff", objectName: "checkout-a", observedAt: Date(timeIntervalSince1970: 100), count: 1)
            ]),
            workloadsSection: .unavailable(reason: "invalid workload JSON"),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.overviewNotice?.id == "section-workloads")
        #expect(display.overviewNotice?.title == "Workloads unavailable")
        #expect(display.overviewNotice?.message == "invalid workload JSON")
    }

    @Test("overview notice falls back to first warning event")
    func overviewNoticeFallsBackToFirstWarningEvent() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(reason: "BackOff", objectName: "checkout-a", observedAt: Date(timeIntervalSince1970: 100), count: 1)
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.overviewNotice?.id == "event-BackOff|Pod|api|checkout-a")
        #expect(display.overviewNotice?.title == "BackOff")
        #expect(display.overviewNotice?.message == "BackOff api/pod/checkout-a 2m ago")
    }

    @Test("events tab rows are capped at three grouped warnings")
    func eventsTabRowsAreCappedAtThreeGroupedWarnings() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([
                warningEvent(reason: "BackOff", objectName: "checkout-a", observedAt: Date(timeIntervalSince1970: 100), count: 1),
                warningEvent(reason: "FailedScheduling", objectName: "checkout-b", observedAt: Date(timeIntervalSince1970: 90), count: 1),
                warningEvent(reason: "Unhealthy", objectName: "checkout-c", observedAt: Date(timeIntervalSince1970: 80), count: 1),
                warningEvent(reason: "Pulled", objectName: "checkout-d", observedAt: Date(timeIntervalSince1970: 70), count: 1)
            ]),
            workloadsSection: .available([]),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.eventsTab.rows.count == 3)
    }

    @Test("events tab preserves warning count when grouped rows are unavailable")
    func eventsTabPreservesWarningCountWhenGroupedRowsAreUnavailable() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodeSummary: NodeSummary(ready: 3, total: 3),
            podSummary: PodSummary(running: 12, total: 12),
            warningEventCount: 1,
            trackedItems: [],
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

        #expect(display.eventsTab.rows.isEmpty)
        #expect(display.eventsTab.emptyMessage == "1 warning event needs review")
    }

    @Test("unavailable section prevents otherwise healthy ok state")
    func unavailableSectionPreventsOtherwiseHealthyOKState() {
        let snapshot = ClusterSnapshot(
            contextName: "prod",
            nodesSection: .available(NodeSummary(ready: 3, total: 3)),
            podsSection: .available(PodSummary(running: 12, total: 12)),
            warningEventsSection: .available([]),
            workloadsSection: .unavailable(reason: "invalid workload JSON"),
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 220))

        #expect(display.state == .watch)
    }
}

@Suite("Health State Shift Alerts")
struct HealthStateShiftAlertTests {
    @Test("first fresh display establishes baseline without alert")
    func firstFreshDisplayEstablishesBaselineWithoutAlert() {
        var tracker = HealthShiftAlertTracker()

        let alert = tracker.record(alertDisplay(state: .ok, reason: "All watched targets OK"))

        #expect(alert == nil)
    }

    @Test("fresh health category deterioration emits alert")
    func freshHealthCategoryDeteriorationEmitsAlert() throws {
        var tracker = HealthShiftAlertTracker()
        _ = tracker.record(alertDisplay(state: .ok, reason: "All watched targets OK"))

        let maybeAlert = tracker.record(alertDisplay(state: .bad, reason: "api/checkout needs attention"))
        let alert = try #require(maybeAlert)

        #expect(alert.title == "Kubebar: prod is Bad")
        #expect(alert.body == "api/checkout needs attention")
    }

    @Test("watch to bad deterioration emits alert")
    func watchToBadDeteriorationEmitsAlert() throws {
        var tracker = HealthShiftAlertTracker()
        _ = tracker.record(alertDisplay(state: .watch, reason: "1 warning event"))

        let maybeAlert = tracker.record(alertDisplay(state: .bad, reason: "api/checkout needs attention"))
        let alert = try #require(maybeAlert)

        #expect(alert.title.contains("Bad"))
    }

    @Test("stale display does not emit or replace fresh baseline")
    func staleDisplayDoesNotEmitOrReplaceFreshBaseline() throws {
        var tracker = HealthShiftAlertTracker()
        _ = tracker.record(alertDisplay(state: .ok, reason: "All watched targets OK"))

        #expect(tracker.record(alertDisplay(state: .stale, reason: "kubectl timed out", stale: true)) == nil)

        let maybeAlert = tracker.record(alertDisplay(state: .bad, reason: "api/checkout needs attention"))
        let alert = try #require(maybeAlert)
        #expect(alert.title.contains("Bad"))
    }

    @Test("unchanged bad state does not re-notify")
    func unchangedBadStateDoesNotRenotify() throws {
        var tracker = HealthShiftAlertTracker()
        _ = tracker.record(alertDisplay(state: .ok, reason: "All watched targets OK"))

        let badDisplay = alertDisplay(
            state: .bad,
            reason: "api/checkout needs attention",
            watchItems: [watchItem(id: "api-checkout", title: "api/checkout", state: .bad, reason: "1 pod restarting")]
        )

        let firstAlert = tracker.record(badDisplay)
        _ = try #require(firstAlert)
        #expect(tracker.record(badDisplay) == nil)
    }

    @Test("bad reason change alone does not re-notify")
    func badReasonChangeAloneDoesNotRenotify() throws {
        var tracker = HealthShiftAlertTracker()
        let twoRestarting = alertDisplay(
            state: .bad,
            reason: "api/checkout needs attention",
            watchItems: [watchItem(id: "api-checkout", title: "api/checkout", state: .bad, reason: "2 pods restarting")]
        )
        _ = tracker.record(twoRestarting)

        let oneRestarting = alertDisplay(
            state: .bad,
            reason: "api/checkout needs attention",
            watchItems: [watchItem(id: "api-checkout", title: "api/checkout", state: .bad, reason: "1 pod restarting")]
        )

        #expect(tracker.record(oneRestarting) == nil)
    }

    @Test("bad affected pod count increase emits alert")
    func badAffectedPodCountIncreaseEmitsAlert() throws {
        var tracker = HealthShiftAlertTracker()
        _ = tracker.record(
            alertDisplay(
                state: .bad,
                reason: "api/checkout needs attention",
                watchItems: [
                    watchItem(
                        id: "api-checkout",
                        title: "api/checkout",
                        state: .bad,
                        reason: "1 pod restarting",
                        affectedPodCount: 1
                    )
                ]
            )
        )

        let maybeAlert = tracker.record(
            alertDisplay(
                state: .bad,
                reason: "api/checkout needs attention",
                watchItems: [
                    watchItem(
                        id: "api-checkout",
                        title: "api/checkout",
                        state: .bad,
                        reason: "2 pods restarting",
                        affectedPodCount: 2
                    )
                ]
            )
        )

        let alert = try #require(maybeAlert)
        #expect(alert.title == "Kubebar: api/checkout is Bad")
        #expect(alert.body == "2 pods restarting")
    }

    @Test("newly bad watchlist item emits alert while top state stays bad")
    func newlyBadWatchlistItemEmitsAlertWhileTopStateStaysBad() throws {
        var tracker = HealthShiftAlertTracker()
        _ = tracker.record(alertDisplay(state: .ok, reason: "All watched targets OK"))

        let firstBad = alertDisplay(
            state: .bad,
            reason: "api/checkout needs attention",
            watchItems: [watchItem(id: "api-checkout", title: "api/checkout", state: .bad, reason: "1 pod restarting")]
        )
        let firstAlert = tracker.record(firstBad)
        _ = try #require(firstAlert)

        let secondBad = alertDisplay(
            state: .bad,
            reason: "ops/worker needs attention",
            watchItems: [
                watchItem(id: "api-checkout", title: "api/checkout", state: .bad, reason: "1 pod restarting"),
                watchItem(id: "ops-worker", title: "ops/worker", state: .bad, reason: "1 pod restarting")
            ]
        )

        let maybeAlert = tracker.record(secondBad)
        let alert = try #require(maybeAlert)
        #expect(alert.title == "Kubebar: ops/worker is Bad")
        #expect(alert.body == "1 pod restarting")
    }

    @Test("hidden newly bad watchlist item emits alert")
    func hiddenNewlyBadWatchlistItemEmitsAlert() throws {
        var tracker = HealthShiftAlertTracker()
        let visibleBadItems = (1...5).map { index in
            watchItem(id: "team-bad-\(index)", title: "team/bad-\(index)", state: .bad, reason: "1 pod restarting")
        }
        let hiddenOk = watchItem(id: "team-hidden", title: "team/hidden", state: .ok, reason: "ready")
        let hiddenBad = watchItem(id: "team-hidden", title: "team/hidden", state: .bad, reason: "1 pod restarting")

        _ = tracker.record(
            alertDisplay(
                state: .bad,
                reason: "5 watched targets need attention",
                watchItems: visibleBadItems,
                alertWatchItems: visibleBadItems + [hiddenOk],
                hiddenWatchItemCount: 1
            )
        )

        let maybeAlert = tracker.record(
            alertDisplay(
                state: .bad,
                reason: "6 watched targets need attention",
                watchItems: visibleBadItems,
                alertWatchItems: visibleBadItems + [hiddenBad],
                hiddenWatchItemCount: 1
            )
        )

        let alert = try #require(maybeAlert)
        #expect(alert.title == "Kubebar: team/hidden is Bad")
        #expect(alert.body == "1 pod restarting")
    }

    @Test("same named workload kinds keep distinct alert identities")
    func sameNamedWorkloadKindsKeepDistinctAlertIdentities() {
        let display = sameNamedWorkloadKindsDisplay(
            deploymentState: .bad,
            deploymentReason: "deployment already bad",
            statefulSetState: .ok,
            statefulSetReason: "statefulset ready"
        )

        #expect(display.alertWatchItems.map(\.title) == ["team/api", "team/api"])
        #expect(display.alertWatchItems.map(\.id) == [
            "workload:deployment:team:api",
            "workload:statefulSet:team:api"
        ])
    }

    @Test("same named workload kinds do not re-notify unchanged mixed state")
    func sameNamedWorkloadKindsDoNotRenotifyUnchangedMixedState() {
        var tracker = HealthShiftAlertTracker()
        let display = sameNamedWorkloadKindsDisplay(
            deploymentState: .bad,
            deploymentReason: "deployment already bad",
            statefulSetState: .ok,
            statefulSetReason: "statefulset ready"
        )

        _ = tracker.record(display)

        #expect(tracker.record(display) == nil)
    }

    @Test("same named workload kinds alert on the correct newly bad kind")
    func sameNamedWorkloadKindsAlertOnCorrectNewlyBadKind() throws {
        var tracker = HealthShiftAlertTracker()
        _ = tracker.record(
            sameNamedWorkloadKindsDisplay(
                deploymentState: .bad,
                deploymentReason: "deployment already bad",
                statefulSetState: .ok,
                statefulSetReason: "statefulset ready"
            )
        )

        let maybeAlert = tracker.record(
            sameNamedWorkloadKindsDisplay(
                deploymentState: .bad,
                deploymentReason: "deployment already bad",
                statefulSetState: .bad,
                statefulSetReason: "statefulset now bad"
            )
        )

        let alert = try #require(maybeAlert)
        #expect(alert.title == "Kubebar: team/api is Bad")
        #expect(alert.body == "statefulset now bad")
    }
}

private func warningEvent(
    reason: String,
    namespace: String? = "api",
    objectKind: String? = "Pod",
    objectName: String? = "checkout",
    observedAt: Date?,
    count: Int,
    message: String? = nil
) -> WarningEventRecord {
    WarningEventRecord(
        reason: reason,
        namespace: namespace,
        objectKind: objectKind,
        objectName: objectName,
        message: message,
        observedAt: observedAt,
        count: count
    )
}

private func metricsSummary() -> ClusterMetricsSummary {
    ClusterMetricsSummary(
        cpuUsageNanocores: 750_000_000,
        cpuAllocatableNanocores: 3_500_000_000,
        memoryUsageBytes: 2_147_483_648,
        memoryAllocatableBytes: 12_884_901_888
    )
}

private func nodeDetail(
    name: String,
    isReady: Bool,
    issueReason: String? = nil,
    issueMessage: String? = nil,
    cpuUsageNanocores: Int64? = 500_000_000,
    cpuAllocatableNanocores: Int64? = 2_000_000_000,
    memoryUsageBytes: Int64? = 1_073_741_824,
    memoryAllocatableBytes: Int64? = 4_294_967_296
) -> NodeDetail {
    NodeDetail(
        name: name,
        isReady: isReady,
        issueReason: issueReason,
        issueMessage: issueMessage,
        cpuUsageNanocores: cpuUsageNanocores,
        cpuAllocatableNanocores: cpuAllocatableNanocores,
        memoryUsageBytes: memoryUsageBytes,
        memoryAllocatableBytes: memoryAllocatableBytes
    )
}

private func podDetail(
    namespace: String,
    name: String,
    phase: String? = "Running",
    readyContainerCount: Int? = nil,
    totalContainerCount: Int? = nil,
    statusReason: String? = nil,
    statusMessage: String? = nil,
    waitingReason: String? = nil,
    waitingMessage: String? = nil,
    terminatedReason: String? = nil,
    terminatedMessage: String? = nil,
    notReadyConditionReason: String? = nil,
    notReadyConditionMessage: String? = nil,
    hasUnreadyContainer: Bool = false,
    isFailed: Bool = false,
    isPending: Bool = false,
    isUnknown: Bool = false,
    isNotReady: Bool = false,
    resourceSummary: PodResourceSummary = PodResourceSummary()
) -> PodDetail {
    PodDetail(
        namespace: namespace,
        name: name,
        phase: phase,
        readyContainerCount: readyContainerCount,
        totalContainerCount: totalContainerCount,
        statusReason: statusReason,
        statusMessage: statusMessage,
        waitingReason: waitingReason,
        waitingMessage: waitingMessage,
        terminatedReason: terminatedReason,
        terminatedMessage: terminatedMessage,
        notReadyConditionReason: notReadyConditionReason,
        notReadyConditionMessage: notReadyConditionMessage,
        hasUnreadyContainer: hasUnreadyContainer,
        isFailed: isFailed,
        isPending: isPending,
        isUnknown: isUnknown,
        isNotReady: isNotReady,
        resourceSummary: resourceSummary
    )
}

private func alertDisplay(
    state: ClusterHealthState,
    reason: String,
    watchItems: [WatchItemDisplay] = [],
    alertWatchItems: [WatchItemDisplay]? = nil,
    hiddenWatchItemCount: Int = 0,
    stale: Bool = false
) -> MenuDisplayModel {
    MenuDisplayModel(
        state: state,
        contextName: "prod",
        healthSentence: reason,
        primaryStatusReason: reason,
        lastUpdated: "now",
        counters: MenuCounters(nodes: "1/1", pods: "1/1", warningEvents: "0"),
        visibleWatchItems: watchItems,
        alertWatchItems: alertWatchItems,
        hiddenWatchItemCount: hiddenWatchItemCount,
        staleBanner: stale ? StaleBannerDisplay(lastUpdated: "now", reason: reason) : nil
    )
}

private func sameNamedWorkloadKindsDisplay(
    deploymentState: ClusterHealthState,
    deploymentReason: String,
    statefulSetState: ClusterHealthState,
    statefulSetReason: String
) -> MenuDisplayModel {
    let snapshot = ClusterSnapshot(
        contextName: "prod",
        nodeSummary: NodeSummary(ready: 1, total: 1),
        podSummary: PodSummary(running: 1, total: 1),
        warningEventCount: 0,
        trackedItems: [
            TrackedItemStatus(
                target: .workload(namespace: "team", name: "api", kind: .deployment),
                state: deploymentState,
                reason: deploymentReason
            ),
            TrackedItemStatus(
                target: .workload(namespace: "team", name: "api", kind: .statefulSet),
                state: statefulSetState,
                reason: statefulSetReason
            )
        ],
        capturedAt: Date(timeIntervalSince1970: 100)
    )

    return HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))
}

private func watchItem(
    id: String,
    title: String,
    state: ClusterHealthState,
    reason: String,
    affectedPodCount: Int? = nil
) -> WatchItemDisplay {
    WatchItemDisplay(
        id: id,
        title: title,
        state: state,
        reason: reason,
        detail: WatchItemDetailDisplay(
            stateLabel: state.label,
            reason: reason,
            affectedPodCount: affectedPodCount
        )
    )
}
