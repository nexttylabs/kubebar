import Foundation

public struct RefreshFailure: Equatable, Sendable {
    public let reason: String

    public init(reason: String) {
        self.reason = reason
    }
}

public struct HealthEvaluator: Sendable {
    private let healthyWatchItemLimit: Int
    private let attentionWatchItemLimit: Int
    private let warningEventSummaryLimit = 3
    private let overviewWarningLimit = 2
    private let warningMessageLimit = 96

    public init(visibleWatchItemLimit: Int = 5, healthyWatchItemLimit: Int = 3) {
        self.attentionWatchItemLimit = visibleWatchItemLimit
        self.healthyWatchItemLimit = min(healthyWatchItemLimit, visibleWatchItemLimit)
    }

    public func evaluate(
        snapshot: ClusterSnapshot?,
        previousSnapshot: ClusterSnapshot? = nil,
        failure: RefreshFailure? = nil,
        now: Date,
        staleAfterSeconds: Int? = nil
    ) -> MenuDisplayModel {
        if let snapshot {
            return displayModel(
                from: snapshot,
                stateOverride: nil,
                failureReason: failure?.reason,
                now: now,
                staleAfterSeconds: staleAfterSeconds
            )
        }

        if let previousSnapshot {
            return displayModel(
                from: previousSnapshot,
                stateOverride: .stale,
                failureReason: failure?.reason,
                now: now,
                staleAfterSeconds: staleAfterSeconds
            )
        }

        return MenuDisplayModel(
            state: .stale,
            contextName: "Not configured",
            healthSentence: "Status unavailable",
            primaryStatusReason: failure?.reason ?? "No previous cluster data",
            lastUpdated: "never",
            counters: MenuCounters(nodes: "-", pods: "-", warningEvents: "-"),
            visibleWatchItems: [],
            hiddenWatchItemCount: 0,
            staleBanner: StaleBannerDisplay(lastUpdated: "never", reason: failure?.reason ?? "No previous cluster data"),
            overview: unavailableOverview(
                contextName: "Not configured",
                reason: failure?.reason ?? "No previous cluster data"
            )
        )
    }

    private func displayModel(
        from snapshot: ClusterSnapshot,
        stateOverride: ClusterHealthState?,
        failureReason: String?,
        now: Date,
        staleAfterSeconds: Int?
    ) -> MenuDisplayModel {
        let sortedItems = sortByAttention(snapshot.trackedItems)
        let visibleLimit = visibleWatchItemLimit(for: sortedItems)
        let visibleItems = sortedItems.prefix(visibleLimit).map { makeDisplayItem($0, now: now) }
        let hiddenCount = max(0, sortedItems.count - visibleItems.count)
        let freshnessReason = staleAgeOutReason(for: snapshot, now: now, staleAfterSeconds: staleAfterSeconds)
        let resolvedState = stateOverride ?? (freshnessReason == nil ? evaluateState(snapshot) : .stale)
        let pinnedWarningIDs = pinnedWarningIDs(from: snapshot.trackedItems)
        let warningEventSummaries = makeWarningEventSummaries(
            from: snapshot.warningEventsSection.value ?? [],
            now: now,
            pinnedWarningIDs: [],
            limit: warningEventSummaryLimit
        )
        let overviewWarningRows = makeWarningEventSummaries(
            from: snapshot.warningEventsSection.value ?? [],
            now: now,
            pinnedWarningIDs: pinnedWarningIDs,
            limit: Int.max
        )
        let overviewWarnings = Array(overviewWarningRows.prefix(overviewWarningLimit))
        let sectionNotices = makeSectionNotices(from: snapshot.sectionFailures)
        let staleReason = failureReason ?? freshnessReason
        let lastUpdated = relativeAge(from: snapshot.capturedAt, to: now)
        let primaryStatusReason = primaryStatusReason(
            for: resolvedState,
            snapshot: snapshot,
            visibleItems: visibleItems,
            sectionNotices: sectionNotices,
            staleReason: staleReason
        )

        return MenuDisplayModel(
            state: resolvedState,
            contextName: snapshot.contextName,
            healthSentence: healthSentence(for: resolvedState, visibleItems: visibleItems),
            primaryStatusReason: primaryStatusReason,
            lastUpdated: lastUpdated,
            counters: menuCounters(from: snapshot),
            visibleWatchItems: visibleItems,
            hiddenWatchItemCount: hiddenCount,
            staleBanner: staleBanner(
                for: resolvedState,
                snapshot: snapshot,
                failureReason: staleReason,
                now: now
            ),
            warningEventSummaries: warningEventSummaries,
            sectionNotices: sectionNotices,
            overviewNotice: makeOverviewNotice(sectionNotices: sectionNotices, warningEventSummaries: warningEventSummaries),
            overview: makeOverview(
                from: snapshot,
                state: resolvedState,
                primaryStatusReason: primaryStatusReason,
                lastUpdated: lastUpdated,
                visibleItems: Array(visibleItems),
                sectionNotices: sectionNotices,
                warningRows: overviewWarnings,
                totalWarningRows: overviewWarningRows.count,
                k9sHandoff: k9sHandoffTarget(from: snapshot, state: resolvedState)
            ),
            nodeTab: makeNodeTab(from: snapshot, sectionNotices: sectionNotices),
            podTab: makePodTab(from: snapshot, visibleItems: Array(visibleItems), sectionNotices: sectionNotices),
            eventsTab: makeEventsTab(from: snapshot, rows: warningEventSummaries, sectionNotices: sectionNotices)
        )
    }

    private func staleAgeOutReason(for snapshot: ClusterSnapshot, now: Date, staleAfterSeconds: Int?) -> String? {
        guard let staleAfterSeconds else {
            return nil
        }

        let ageSeconds = max(0, Int(now.timeIntervalSince(snapshot.capturedAt)))
        return ageSeconds > staleAfterSeconds ? "Last refresh is too old" : nil
    }

    private func evaluateState(_ snapshot: ClusterSnapshot) -> ClusterHealthState {
        if snapshot.nodesSection.value.map({ $0.ready < $0.total }) == true ||
            snapshot.trackedItems.contains(where: { $0.state == .bad }) {
            return .bad
        }

        if snapshot.podsSection.value.map({ $0.ready < $0.total }) == true ||
            snapshot.warningEventsSection.value.map({ !$0.isEmpty }) == true ||
            snapshot.trackedItems.contains(where: { $0.state == .watch }) ||
            !snapshot.sectionFailures.isEmpty {
            return .watch
        }

        return .ok
    }

    private func menuCounters(from snapshot: ClusterSnapshot) -> MenuCounters {
        MenuCounters(
            nodes: snapshot.nodesSection.value.map { "\($0.ready)/\($0.total)" } ?? "-",
            pods: snapshot.podsSection.value.map { "\($0.running)/\($0.total)" } ?? "-",
            warningEvents: snapshot.warningEventsSection.value.map { _ in "\(snapshot.warningEventCount)" } ?? "-"
        )
    }

    private func makeSectionNotices(from sectionFailures: [SnapshotSectionFailure]) -> [SectionAvailabilityDisplay] {
        sectionFailures.map { failure in
            SectionAvailabilityDisplay(
                id: failure.section.rawValue,
                title: failure.section.displayName,
                reason: sanitizedSectionReason(failure.reason)
            )
        }
    }

    private func makeOverviewNotice(
        sectionNotices: [SectionAvailabilityDisplay],
        warningEventSummaries: [WarningEventDisplay]
    ) -> OverviewNoticeDisplay? {
        if let notice = sectionNotices.first {
            return OverviewNoticeDisplay(
                id: "section-\(notice.id)",
                title: "\(notice.title) unavailable",
                message: notice.reason
            )
        }

        return warningEventSummaries.first.map { event in
            OverviewNoticeDisplay(
                id: "event-\(event.id)",
                title: event.reason,
                message: event.summary
            )
        }
    }

    private func makeOverview(
        from snapshot: ClusterSnapshot,
        state: ClusterHealthState,
        primaryStatusReason: String,
        lastUpdated: String,
        visibleItems: [WatchItemDisplay],
        sectionNotices: [SectionAvailabilityDisplay],
        warningRows: [WarningEventDisplay],
        totalWarningRows: Int,
        k9sHandoff: OverviewK9sHandoff?
    ) -> OverviewDisplay {
        let statusHelpText = primaryStatusHelpText(
            for: state,
            snapshot: snapshot,
            visibleItems: visibleItems,
            sectionNotices: sectionNotices,
            staleReason: state == .stale ? primaryStatusReason : nil,
            lastUpdated: lastUpdated,
            warningRows: warningRows,
            fallback: primaryStatusReason
        )

        return OverviewDisplay(
            statusText: primaryStatusReason,
            statusHelpText: statusHelpText,
            statusAccessibilityLabel: statusAccessibilityLabel(
                state: state,
                statusText: primaryStatusReason,
                statusHelpText: statusHelpText,
                contextName: snapshot.contextName
            ),
            k9sHandoff: k9sHandoff,
            cards: [
                nodeOverviewCard(from: snapshot, state: state),
                podOverviewCard(from: snapshot, state: state),
                cpuOverviewCard(from: snapshot, state: state),
                memoryOverviewCard(from: snapshot, state: state)
            ],
            recentWarnings: warningRows,
            recentWarningsOverflowCount: max(0, totalWarningRows - warningRows.count),
            recentWarningsEmptyMessage: snapshot.warningEventsSection.value == nil
                ? "Warning event count unavailable"
                : warningEventsEmptyMessage(count: snapshot.warningEventCount),
            recentWarningsUnavailableMessage: tabUnavailableMessage(
                sectionID: SnapshotSectionName.warningEvents.rawValue,
                prefix: "Warning events unavailable",
                sectionNotices: sectionNotices
            )
        )
    }

    private func unavailableOverview(contextName: String, reason: String) -> OverviewDisplay {
        OverviewDisplay(
            statusText: reason,
            statusHelpText: reason,
            statusAccessibilityLabel: statusAccessibilityLabel(
                state: .stale,
                statusText: reason,
                statusHelpText: reason,
                contextName: contextName
            ),
            cards: [
                unavailableOverviewCard(id: "nodes", title: "Nodes", systemImageName: "server.rack", reason: reason),
                unavailableOverviewCard(id: "pods", title: "Pods", systemImageName: "shippingbox", reason: reason),
                unavailableOverviewCard(id: "cpu", title: "CPU", systemImageName: "cpu", reason: reason),
                unavailableOverviewCard(id: "memory", title: "Memory", systemImageName: "memorychip", reason: reason)
            ],
            recentWarnings: [],
            recentWarningsOverflowCount: 0,
            recentWarningsEmptyMessage: "Warning event count unavailable"
        )
    }

    private func k9sHandoffTarget(from snapshot: ClusterSnapshot, state: ClusterHealthState) -> OverviewK9sHandoff? {
        guard state == .watch || state == .bad else {
            return nil
        }

        let sortedTrackedItems = sortByAttention(snapshot.trackedItems)
        guard let item = sortedTrackedItems.first(where: { $0.state == .bad || $0.state == .watch }),
              let target = handoffTarget(for: item.target, contextName: snapshot.contextName)
        else {
            return nil
        }

        return OverviewK9sHandoff(
            target: target,
            actionLabel: "Open in k9s",
            helpText: "Open watched target in k9s",
            accessibilityLabel: "Open watched target in k9s"
        )
    }

    private func handoffTarget(for target: WatchTarget, contextName: String) -> K9sHandoffTarget? {
        guard let normalizedContextName = normalizedText(contextName), !normalizedContextName.isEmpty,
              normalizedContextName != "Not configured"
        else {
            return nil
        }

        switch target {
        case let .namespace(namespace):
            guard let normalizedNamespace = normalizedText(namespace), !normalizedNamespace.isEmpty else {
                return nil
            }

            return K9sHandoffTarget(contextName: normalizedContextName, namespace: normalizedNamespace)
        case let .workload(namespace: namespace, _, _):
            guard let normalizedNamespace = normalizedText(namespace), !normalizedNamespace.isEmpty else {
                return nil
            }

            return K9sHandoffTarget(contextName: normalizedContextName, namespace: normalizedNamespace)
        }
    }

    private func nodeOverviewCard(from snapshot: ClusterSnapshot, state: ClusterHealthState) -> OverviewCardDisplay {
        switch snapshot.nodesSection {
        case let .available(summary):
            return OverviewCardDisplay(
                id: "nodes",
                title: "Nodes",
                value: "\(summary.ready)/\(summary.total)",
                detail: "ready",
                systemImageName: "server.rack",
                state: cardState(for: state),
                accessibilityLabel: "Nodes \(summary.ready) of \(summary.total) ready"
            )
        case let .unavailable(reason):
            let reason = sanitizedSectionReason(reason)
            return unavailableOverviewCard(
                id: "nodes",
                title: "Nodes",
                systemImageName: "server.rack",
                reason: reason
            )
        }
    }

    private func podOverviewCard(from snapshot: ClusterSnapshot, state: ClusterHealthState) -> OverviewCardDisplay {
        switch snapshot.podsSection {
        case let .available(summary):
            return OverviewCardDisplay(
                id: "pods",
                title: "Pods",
                value: "\(summary.ready)/\(summary.total)",
                detail: "ready",
                systemImageName: "shippingbox",
                state: cardState(for: state),
                accessibilityLabel: "Pods \(summary.ready) of \(summary.total) ready"
            )
        case let .unavailable(reason):
            let reason = sanitizedSectionReason(reason)
            return unavailableOverviewCard(
                id: "pods",
                title: "Pods",
                systemImageName: "shippingbox",
                reason: reason
            )
        }
    }

    private func cpuOverviewCard(from snapshot: ClusterSnapshot, state: ClusterHealthState) -> OverviewCardDisplay {
        guard let metrics = snapshot.metricsSection.value else {
            return unavailableOverviewCard(
                id: "cpu",
                title: "CPU",
                systemImageName: "cpu",
                reason: sanitizedSectionReason(snapshot.metricsSection.unavailableReason ?? "Metrics unavailable")
            )
        }

        let percent = percentage(usage: metrics.cpuUsageNanocores, allocatable: metrics.cpuAllocatableNanocores)
        let detail = "\(formatCores(metrics.cpuUsageNanocores)) / \(formatCores(metrics.cpuAllocatableNanocores)) cores"
        return OverviewCardDisplay(
            id: "cpu",
            title: "CPU",
            value: percent,
            detail: detail,
            systemImageName: "cpu",
            state: cardState(for: state),
            accessibilityLabel: "CPU \(percent), \(detail)"
        )
    }

    private func memoryOverviewCard(from snapshot: ClusterSnapshot, state: ClusterHealthState) -> OverviewCardDisplay {
        guard let metrics = snapshot.metricsSection.value else {
            return unavailableOverviewCard(
                id: "memory",
                title: "Memory",
                systemImageName: "memorychip",
                reason: sanitizedSectionReason(snapshot.metricsSection.unavailableReason ?? "Metrics unavailable")
            )
        }

        let percent = percentage(usage: metrics.memoryUsageBytes, allocatable: metrics.memoryAllocatableBytes)
        let detail = "\(formatGiB(metrics.memoryUsageBytes)) / \(formatGiB(metrics.memoryAllocatableBytes)) GiB"
        return OverviewCardDisplay(
            id: "memory",
            title: "Memory",
            value: percent,
            detail: detail,
            systemImageName: "memorychip",
            state: cardState(for: state),
            accessibilityLabel: "Memory \(percent), \(detail)"
        )
    }

    private func unavailableOverviewCard(id: String, title: String, systemImageName: String, reason: String) -> OverviewCardDisplay {
        OverviewCardDisplay(
            id: id,
            title: title,
            value: "-",
            detail: reason,
            systemImageName: systemImageName,
            state: .unavailable,
            accessibilityLabel: "\(title) unavailable, \(reason)"
        )
    }

    private func cardState(for state: ClusterHealthState) -> OverviewCardState {
        state == .stale ? .stale : .current
    }

    private func percentage(usage: Int64, allocatable: Int64) -> String {
        guard allocatable > 0 else {
            return "-"
        }

        let percent = (Double(usage) / Double(allocatable) * 100).rounded()
        return "\(Int(percent))%"
    }

    private func percentage(usage: Int64?, allocatable: Int64?) -> String {
        guard let usage, let allocatable else {
            return "-"
        }

        return percentage(usage: usage, allocatable: allocatable)
    }

    private func formatCores(_ nanocores: Int64) -> String {
        formatDecimal(Double(nanocores) / 1_000_000_000)
    }

    private func formatGiB(_ bytes: Int64) -> String {
        formatDecimal(Double(bytes) / 1_073_741_824)
    }

    private func formatDecimal(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == floor(rounded) {
            return "\(Int(rounded))"
        }

        return String(format: "%.1f", rounded)
    }

    private func makeNodeTab(from snapshot: ClusterSnapshot, sectionNotices: [SectionAvailabilityDisplay]) -> NodeTabDisplay {
        NodeTabDisplay(
            summary: snapshot.nodesSection.value.map { "\($0.ready)/\($0.total) nodes ready" } ?? "- nodes ready",
            rows: makeNodeRows(from: snapshot),
            showsEmptyMessage: snapshot.nodesSection.value?.total == 0,
            unavailableMessage: tabUnavailableMessage(
                sectionID: SnapshotSectionName.nodes.rawValue,
                prefix: "Node data unavailable",
                sectionNotices: sectionNotices
            )
        )
    }

    private func makeNodeRows(from snapshot: ClusterSnapshot) -> [NodeItemDisplay] {
        guard snapshot.nodesSection.isAvailable, let details = snapshot.nodeDetailsSection.value else {
            return []
        }

        return details
            .sorted { left, right in
                if left.isReady != right.isReady {
                    return !left.isReady
                }

                return left.name < right.name
            }
            .map(makeNodeRow)
    }

    private func makeNodeRow(from detail: NodeDetail) -> NodeItemDisplay {
        let readiness: NodeItemReadiness = detail.isReady ? .ready : .notReady
        let statusLabel = detail.isReady ? "Ready" : "Not Ready"
        let cpuLabel = percentage(usage: detail.cpuUsageNanocores, allocatable: detail.cpuAllocatableNanocores)
        let memoryLabel = percentage(usage: detail.memoryUsageBytes, allocatable: detail.memoryAllocatableBytes)
        let issueText = detail.isReady ? nil : nodeIssueText(from: detail)
        let helpText = nodeHelpText(
            name: detail.name,
            statusLabel: statusLabel,
            cpuLabel: cpuLabel,
            memoryLabel: memoryLabel,
            issueText: issueText
        )

        return NodeItemDisplay(
            name: detail.name,
            readiness: readiness,
            statusLabel: statusLabel,
            cpuLabel: cpuLabel,
            memoryLabel: memoryLabel,
            issueText: issueText,
            helpText: helpText,
            accessibilityLabel: helpText
        )
    }

    private func nodeIssueText(from detail: NodeDetail) -> String {
        let reason = normalizedText(detail.issueReason)
        let message = normalizedText(detail.issueMessage)

        if let reason, let message, reason != message {
            return "\(reason): \(message)"
        }

        if let reason {
            return reason
        }

        if let message {
            return message
        }

        return "Node is not ready"
    }

    private func nodeHelpText(
        name: String,
        statusLabel: String,
        cpuLabel: String,
        memoryLabel: String,
        issueText: String?
    ) -> String {
        var parts = [
            name,
            statusLabel,
            "CPU \(cpuLabel)",
            "Memory \(memoryLabel)"
        ]

        if let issueText {
            parts.append(issueText)
        }

        return parts.joined(separator: ", ")
    }

    private func makePodTab(
        from snapshot: ClusterSnapshot,
        visibleItems: [WatchItemDisplay],
        sectionNotices: [SectionAvailabilityDisplay]
    ) -> PodTabDisplay {
        let podDetails = snapshot.podDetailsSection.value
        let sections = podDetails.map(makePodSections) ?? []

        return PodTabDisplay(
            summary: podTabSummary(from: snapshot, podDetails: podDetails),
            sections: sections,
            rows: visibleItems,
            unavailableMessage: tabUnavailableMessage(
                sectionID: SnapshotSectionName.pods.rawValue,
                prefix: "Pod data unavailable",
                sectionNotices: sectionNotices
            ) ?? tabUnavailableMessage(
                sectionID: SnapshotSectionName.workloads.rawValue,
                prefix: "Workloads unavailable",
                sectionNotices: sectionNotices
            ) ?? snapshot.podDetailsSection.unavailableReason.map { "Pod data unavailable: \(sanitizedSectionReason($0))" },
            emptyMessage: podTabEmptyMessage(from: snapshot, podDetails: podDetails)
        )
    }

    private func podTabSummary(from snapshot: ClusterSnapshot, podDetails: [PodDetail]?) -> String {
        if let podDetails {
            if !podDetails.isEmpty || !snapshot.trackedItems.isEmpty {
                let ready = podDetails.filter { podItemState(from: $0) == .ready }.count
                return "\(ready)/\(podDetails.count) watched pods ready"
            }
        }

        return snapshot.podsSection.value.map { "\($0.running)/\($0.total) pods running" } ?? "- pods running"
    }

    private func podTabEmptyMessage(from snapshot: ClusterSnapshot, podDetails: [PodDetail]?) -> String {
        if let podDetails, podDetails.isEmpty, !snapshot.trackedItems.isEmpty {
            if snapshot.hasCompletedWatchedPods {
                return "No active pods; completed jobs are OK"
            }

            return "No watched pods found"
        }

        return "No pod data yet. Refresh or check Settings."
    }

    private func makePodSections(from podDetails: [PodDetail]) -> [PodNamespaceDisplay] {
        let rowsByNamespace = Dictionary(grouping: podDetails.map(makePodRow), by: \.namespace)

        return rowsByNamespace
            .map { namespace, rows in
                PodNamespaceDisplay(
                    namespace: namespace,
                    rows: rows.sorted { left, right in
                        let leftPriority = podAttentionPriority(for: left.state)
                        let rightPriority = podAttentionPriority(for: right.state)

                        if leftPriority != rightPriority {
                            return leftPriority < rightPriority
                        }

                        return left.name < right.name
                    }
                )
            }
            .sorted { left, right in
                let leftNeedsAttention = left.rows.contains { $0.state != .ready }
                let rightNeedsAttention = right.rows.contains { $0.state != .ready }

                if leftNeedsAttention != rightNeedsAttention {
                    return leftNeedsAttention
                }

                return left.namespace < right.namespace
            }
    }

    private func makePodRow(from detail: PodDetail) -> PodItemDisplay {
        let state = podItemState(from: detail)
        let readyLabel = podReadyLabel(from: detail)
        let resourceLabel = podResourceLabel(from: detail.resourceSummary)
        let resourceHelpLabel = podResourceHelpLabel(from: detail.resourceSummary)
        let fullIssueText = podIssueText(from: detail, state: state)
        let issueText = shortenedText(fullIssueText)
        let helpText = podHelpText(
            detail: detail,
            state: state,
            readyLabel: readyLabel,
            resourceLabel: resourceHelpLabel,
            issueText: fullIssueText
        )

        return PodItemDisplay(
            namespace: detail.namespace,
            name: detail.name,
            state: state,
            readyLabel: readyLabel,
            resourceLabel: resourceLabel,
            issueText: issueText,
            helpText: helpText,
            accessibilityLabel: helpText
        )
    }

    private func podItemState(from detail: PodDetail) -> PodItemState {
        if detail.isFailed ||
            isBadWaitingReason(detail.waitingReason) ||
            isBadTerminatedReason(detail.terminatedReason) {
            return .bad
        }

        if detail.isPending ||
            detail.isUnknown ||
            detail.isNotReady ||
            detail.hasUnreadyContainer {
            return .watch
        }

        return .ready
    }

    private func podAttentionPriority(for state: PodItemState) -> Int {
        switch state {
        case .bad:
            0
        case .watch:
            1
        case .ready:
            2
        }
    }

    private func podReadyLabel(from detail: PodDetail) -> String {
        guard
            let ready = detail.readyContainerCount,
            let total = detail.totalContainerCount,
            total > 0
        else {
            return "-"
        }

        return "\(ready)/\(total)"
    }

    private func podIssueText(from detail: PodDetail, state: PodItemState) -> String? {
        guard state != .ready else {
            return nil
        }

        if let issue = joinedIssue(reason: detail.waitingReason, message: detail.waitingMessage),
           isBadWaitingReason(detail.waitingReason) {
            return issue
        }

        if let issue = joinedIssue(reason: detail.terminatedReason, message: detail.terminatedMessage),
           isBadTerminatedReason(detail.terminatedReason) {
            return issue
        }

        if let issue = joinedIssue(reason: detail.statusReason, message: detail.statusMessage) {
            return issue
        }

        if let issue = joinedIssue(reason: detail.notReadyConditionReason, message: detail.notReadyConditionMessage) {
            return issue
        }

        if let phase = normalizedText(detail.phase), phase != "Running" {
            return phase
        }

        if detail.hasUnreadyContainer {
            return "Containers not ready"
        }

        return state == .bad ? "Pod needs attention" : "Pod is not ready"
    }

    private func joinedIssue(reason: String?, message: String?) -> String? {
        let reason = normalizedText(reason)
        let message = normalizedText(message)

        if let reason, let message, reason != message {
            return "\(reason): \(message)"
        }

        return reason ?? message
    }

    private func podResourceLabel(from summary: PodResourceSummary) -> String {
        let cpuText = podResourceLine(
            name: "CPU",
            usage: summary.cpuUsageNanocores,
            primaryBasisLabel: "req",
            primaryBasis: summary.cpuRequestNanocores,
            secondaryBasisLabel: "limit",
            secondaryBasis: summary.cpuLimitNanocores,
            rawFormatter: formatMillicores
        )

        let memoryText = podResourceLine(
            name: "Mem",
            usage: summary.memoryUsageBytes,
            primaryBasisLabel: "limit",
            primaryBasis: summary.memoryLimitBytes,
            secondaryBasisLabel: "req",
            secondaryBasis: summary.memoryRequestBytes,
            rawFormatter: formatMiB
        )

        return "\(cpuText) · \(memoryText)"
    }

    private func podResourceHelpLabel(from summary: PodResourceSummary) -> String {
        let resourceAvailability = summary.resourceAvailabilityMessage.flatMap { sanitizedSectionReason($0) }
        let label = [
            podResourceFullLine(
                name: "CPU",
                usage: summary.cpuUsageNanocores,
                request: summary.cpuRequestNanocores,
                limit: summary.cpuLimitNanocores,
                format: formatCores,
                suffix: "",
                includeEmpty: true
            ),
            podResourceFullLine(
                name: "Mem",
                usage: summary.memoryUsageBytes,
                request: summary.memoryRequestBytes,
                limit: summary.memoryLimitBytes,
                format: formatGiB,
                suffix: "GiB",
                includeEmpty: true
            )
        ].joined(separator: " · ")

        guard let resourceAvailability else {
            return label
        }

        return "\(label) · \(resourceAvailability)"
    }

    private func podResourceLine(
        name: String,
        usage: Int64?,
        primaryBasisLabel: String,
        primaryBasis: Int64?,
        secondaryBasisLabel: String,
        secondaryBasis: Int64?,
        rawFormatter: (Int64) -> String
    ) -> String {
        guard let usage else {
            return "\(name) -"
        }

        if let primaryBasis, primaryBasis > 0 {
            return "\(name) \(resourcePercentage(usage: usage, basis: primaryBasis)) \(primaryBasisLabel)"
        }

        if let secondaryBasis, secondaryBasis > 0 {
            return "\(name) \(resourcePercentage(usage: usage, basis: secondaryBasis)) \(secondaryBasisLabel)"
        }

        return "\(name) \(rawFormatter(usage))"
    }

    private func resourcePercentage(usage: Int64, basis: Int64) -> String {
        let percent = (Double(usage) / Double(basis) * 100).rounded()
        return "\(Int(percent))%"
    }

    private func formatMillicores(_ nanocores: Int64) -> String {
        "\(formatDecimal(Double(nanocores) / 1_000_000))m"
    }

    private func formatMiB(_ bytes: Int64) -> String {
        "\(formatDecimal(Double(bytes) / 1_048_576))Mi"
    }

    private func podResourceFullLine(
        name: String,
        usage: Int64?,
        request: Int64?,
        limit: Int64?,
        format: (Int64) -> String,
        suffix: String,
        includeEmpty: Bool
    ) -> String {
        if !includeEmpty && usage == nil && request == nil && limit == nil {
            return ""
        }

        let usageText = formatOrDash(usage, formatter: format)
        let requestText = formatOrDash(request, formatter: format)
        let limitText = formatOrDash(limit, formatter: format)

        return "\(name) \(usageText)/\(requestText)/\(limitText)\(suffix)"
    }

    private func formatOrDash(_ value: Int64?, formatter: (Int64) -> String) -> String {
        value.map(formatter) ?? "-"
    }

    private func podHelpText(
        detail: PodDetail,
        state: PodItemState,
        readyLabel: String,
        resourceLabel: String,
        issueText: String?
    ) -> String {
        var parts = [
            "\(detail.namespace)/\(detail.name)",
            state.label,
            readyLabel == "-" ? "container readiness unavailable" : "\(readyLabel) containers ready"
        ]

        if resourceLabel != "-" {
            parts.append(resourceLabel)
        }

        if let issueText {
            parts.append(issueText)
        }

        return parts.joined(separator: ", ")
    }

    private func isBadWaitingReason(_ reason: String?) -> Bool {
        guard let reason = normalizedText(reason)?.lowercased() else {
            return false
        }

        return reason == "crashloopbackoff" ||
            reason == "imagepullbackoff" ||
            reason == "errimagepull" ||
            reason == "invalidimagename" ||
            reason.hasPrefix("createcontainer") ||
            reason.hasPrefix("runcontainer")
    }

    private func isBadTerminatedReason(_ reason: String?) -> Bool {
        guard let reason = normalizedText(reason)?.lowercased() else {
            return false
        }

        return reason != "completed"
    }

    private func makeEventsTab(
        from snapshot: ClusterSnapshot,
        rows: [WarningEventDisplay],
        sectionNotices: [SectionAvailabilityDisplay]
    ) -> EventsTabDisplay {
        EventsTabDisplay(
            rows: rows,
            unavailableMessage: tabUnavailableMessage(
                sectionID: SnapshotSectionName.warningEvents.rawValue,
                prefix: "Warning events unavailable",
                sectionNotices: sectionNotices
            ),
            emptyMessage: warningEventsEmptyMessage(count: snapshot.warningEventCount)
        )
    }

    private func warningEventsEmptyMessage(count: Int) -> String {
        switch count {
        case 0:
            return "No current warning events"
        case 1:
            return "1 warning event needs review"
        default:
            return "\(count) warning events need review"
        }
    }

    private func tabUnavailableMessage(
        sectionID: String,
        prefix: String,
        sectionNotices: [SectionAvailabilityDisplay]
    ) -> String? {
        guard let notice = sectionNotices.first(where: { $0.id == sectionID }) else {
            return nil
        }

        return "\(prefix): \(notice.reason)"
    }

    private func sanitizedSectionReason(_ value: String) -> String {
        normalizedText(value) ?? "Section unavailable"
    }

    private func sortByAttention(_ items: [TrackedItemStatus]) -> [TrackedItemStatus] {
        items.sorted { left, right in
            let leftPriority = attentionPriority(for: left.state)
            let rightPriority = attentionPriority(for: right.state)

            if leftPriority != rightPriority {
                return leftPriority < rightPriority
            }

            return left.target.displayTitle < right.target.displayTitle
        }
    }

    private func visibleWatchItemLimit(for items: [TrackedItemStatus]) -> Int {
        items.contains { $0.state != .ok } ? attentionWatchItemLimit : healthyWatchItemLimit
    }

    private func attentionPriority(for state: ClusterHealthState) -> Int {
        switch state {
        case .bad:
            0
        case .watch:
            1
        case .stale:
            2
        case .ok:
            3
        }
    }

    private func makeDisplayItem(_ item: TrackedItemStatus, now: Date) -> WatchItemDisplay {
        WatchItemDisplay(
            id: item.target.displayTitle,
            title: item.target.displayTitle,
            state: item.state,
            reason: item.reason,
            detail: WatchItemDetailDisplay(
                stateLabel: item.state.label,
                reason: item.reason,
                affectedPodCount: item.affectedPodCount,
                examplePodNames: Array(item.examplePodNames.prefix(3)),
                latestWarning: item.latestWarning.map { makeWarningEventDisplay(from: $0, now: now) }
            )
        )
    }

    private func makeWarningEventSummaries(
        from warningEvents: [WarningEventRecord],
        now: Date,
        pinnedWarningIDs: Set<String>,
        limit: Int
    ) -> [WarningEventDisplay] {
        var groups: [WarningEventGroupKey: WarningEventGroup] = [:]

        for event in warningEvents {
            let key = WarningEventGroupKey(event: event)
            groups[key, default: WarningEventGroup(key: key, reason: event.reason)]
                .add(event, message: normalizedText(event.message))
        }

        return groups.values
            .sorted { left, right in
                let leftPinned = pinnedWarningIDs.contains(left.key.id)
                let rightPinned = pinnedWarningIDs.contains(right.key.id)

                if leftPinned != rightPinned {
                    return leftPinned
                }

                let leftDate = left.observedAt ?? .distantPast
                let rightDate = right.observedAt ?? .distantPast

                if leftDate != rightDate {
                    return leftDate > rightDate
                }

                if left.reason != right.reason {
                    return left.reason < right.reason
                }

                return warningLocation(namespace: left.key.namespace, objectKind: left.key.objectKind, objectName: left.key.objectName) <
                    warningLocation(namespace: right.key.namespace, objectKind: right.key.objectKind, objectName: right.key.objectName)
            }
            .prefix(limit)
            .map { group in
                let fullMessage = group.message
                let isTracked = pinnedWarningIDs.contains(group.key.id)

                return WarningEventDisplay(
                    id: group.key.id,
                    reason: group.reason,
                    location: warningLocation(
                        namespace: group.key.namespace,
                        objectKind: group.key.objectKind,
                        objectName: group.key.objectName
                    ),
                    age: warningAge(from: group.observedAt, to: now),
                    occurrenceCount: group.occurrenceCount,
                    message: shortenedWarningMessage(fullMessage),
                    fullMessage: fullMessage,
                    isTracked: isTracked
                )
            }
    }

    private func pinnedWarningIDs(from trackedItems: [TrackedItemStatus]) -> Set<String> {
        Set(trackedItems.compactMap { item in
            item.latestWarning.map { WarningEventGroupKey(event: $0).id }
        })
    }

    private func makeWarningEventDisplay(from event: WarningEventRecord, now: Date) -> WarningEventDisplay {
        WarningEventDisplay(
            id: WarningEventGroupKey(event: event).id,
            reason: event.reason,
            location: warningLocation(
                namespace: event.namespace,
                objectKind: event.objectKind,
                objectName: event.objectName
            ),
            age: warningAge(from: event.observedAt, to: now),
            occurrenceCount: max(1, event.count),
            message: shortenedWarningMessage(event.message),
            fullMessage: normalizedText(event.message)
        )
    }

    private func warningLocation(namespace: String?, objectKind: String?, objectName: String?) -> String {
        let namespace = normalizedText(namespace)
        let objectKind = normalizedText(objectKind)
        let objectName = normalizedText(objectName)

        if let namespace, let objectKind, let objectName {
            return "\(namespace)/\(objectKind.lowercased())/\(objectName)"
        }

        if let namespace, let objectName {
            return "\(namespace)/\(objectName)"
        }

        if let objectName {
            return objectName
        }

        return "unknown object"
    }

    private func warningAge(from date: Date?, to now: Date) -> String {
        guard let date else {
            return "recently"
        }

        return relativeAge(from: date, to: now)
    }

    private func healthSentence(for state: ClusterHealthState, visibleItems: [WatchItemDisplay]) -> String {
        switch state {
        case .ok:
            return visibleItems.isEmpty ? "No warnings" : "All tracked items OK"
        case .watch:
            return visibleItems.first(where: { $0.state == .watch })?.title.appending(" has warning") ?? "Warnings present"
        case .bad:
            return visibleItems.first(where: { $0.state == .bad })?.title.appending(" needs attention") ?? "Attention required"
        case .stale:
            return "Status is stale"
        }
    }

    private func primaryStatusReason(for state: ClusterHealthState, snapshot: ClusterSnapshot, visibleItems: [WatchItemDisplay], sectionNotices: [SectionAvailabilityDisplay], staleReason: String?) -> String {
        switch state {
        case .ok:
            if snapshot.metricsSection.value == nil {
                return "Metrics unavailable"
            }

            return visibleItems.isEmpty ? "No warnings" : "All tracked items OK"
        case .bad:
            if let reason = visibleItems.first(where: { $0.state == .bad })?.reason {
                return reason
            }

            if let nodeDeficit = nodeDeficit(from: snapshot), nodeDeficit > 0 {
                return countLabel(nodeDeficit, singular: "node", plural: "nodes", suffix: "not ready")
            }

            if let podDeficit = podDeficit(from: snapshot), podDeficit > 0 {
                return countLabel(podDeficit, singular: "pod", plural: "pods", suffix: "not ready")
            }

            return "Attention required"
        case .watch:
            if let reason = visibleItems.first(where: { $0.state == .watch })?.reason {
                return reason
            }

            if let podDeficit = podDeficit(from: snapshot), podDeficit > 0 {
                return countLabel(podDeficit, singular: "pod", plural: "pods", suffix: "not ready")
            }

            if snapshot.warningEventCount > 0 {
                return countLabel(snapshot.warningEventCount, singular: "warning event", plural: "warning events")
            }

            if let sectionReason = sectionNotices.first?.reason {
                return sectionReason
            }

            return "Warnings present"
        case .stale:
            return staleReason ?? "Status is stale"
        }
    }

    private func primaryStatusHelpText(
        for state: ClusterHealthState,
        snapshot: ClusterSnapshot,
        visibleItems: [WatchItemDisplay],
        sectionNotices: [SectionAvailabilityDisplay],
        staleReason: String?,
        lastUpdated: String,
        warningRows: [WarningEventDisplay],
        fallback: String
    ) -> String {
        switch state {
        case .ok:
            if snapshot.metricsSection.value == nil {
                let reason = sanitizedSectionReason(snapshot.metricsSection.unavailableReason ?? "Metrics unavailable")
                return "Metrics unavailable: \(reason)"
            }

            return fallback
        case .bad:
            if let item = visibleItems.first(where: { $0.state == .bad }) {
                return watchItemStatusHelpText(item)
            }

            if let nodeDeficit = nodeDeficit(from: snapshot), nodeDeficit > 0 {
                return firstNotReadyNodeHelpText(from: snapshot) ?? fallback
            }

            if let podDeficit = podDeficit(from: snapshot), podDeficit > 0 {
                return firstAttentionPodHelpText(from: snapshot) ?? fallback
            }

            return fallback
        case .watch:
            if let item = visibleItems.first(where: { $0.state == .watch }) {
                return watchItemStatusHelpText(item)
            }

            if let podDeficit = podDeficit(from: snapshot), podDeficit > 0 {
                return firstAttentionPodHelpText(from: snapshot) ?? fallback
            }

            if let warning = warningRows.first {
                return warning.helpText
            }

            if let notice = sectionNotices.first {
                return "\(notice.title) unavailable: \(notice.reason)"
            }

            return fallback
        case .stale:
            let reason = staleReason ?? "Status is stale"
            return "\(reason), last updated \(lastUpdated)"
        }
    }

    private func statusAccessibilityLabel(
        state: ClusterHealthState,
        statusText: String,
        statusHelpText: String,
        contextName: String
    ) -> String {
        var parts = [state.label]

        if statusHelpText == statusText || statusHelpText.hasPrefix("\(statusText),") || statusHelpText.hasPrefix("\(statusText):") {
            parts.append(statusHelpText)
        } else {
            parts.append(statusText)
            parts.append(statusHelpText)
        }

        parts.append("context \(contextName)")
        return parts.joined(separator: ", ")
    }

    private func watchItemStatusHelpText(_ item: WatchItemDisplay) -> String {
        var parts = ["\(item.title): \(item.detail.reason)"]

        if let affectedPodCount = item.detail.affectedPodCount {
            parts.append(countLabel(affectedPodCount, singular: "affected pod", plural: "affected pods"))
        }

        if !item.detail.examplePodNames.isEmpty {
            parts.append("examples \(item.detail.examplePodNames.joined(separator: ", "))")
        }

        if let latestWarning = item.detail.latestWarning {
            parts.append("latest warning \(latestWarning.helpText)")
        }

        return parts.joined(separator: ", ")
    }

    private func firstNotReadyNodeHelpText(from snapshot: ClusterSnapshot) -> String? {
        makeNodeRows(from: snapshot)
            .first { $0.readiness == .notReady }?
            .helpText
    }

    private func firstAttentionPodHelpText(from snapshot: ClusterSnapshot) -> String? {
        guard let podDetails = snapshot.podDetailsSection.value else {
            return nil
        }

        return makePodSections(from: podDetails)
            .lazy
            .compactMap { section in
                section.rows.first { $0.state != .ready }?.helpText
            }
            .first
    }

    private func countLabel(_ count: Int, singular: String, plural: String, suffix: String? = nil) -> String {
        let noun = count == 1 ? singular : plural
        let suffixText = suffix.map { " \($0)" } ?? ""
        return "\(count) \(noun)\(suffixText)"
    }

    private func nodeDeficit(from snapshot: ClusterSnapshot) -> Int? {
        snapshot.nodesSection.value.map { max(0, $0.total - $0.ready) }
    }

    private func podDeficit(from snapshot: ClusterSnapshot) -> Int? {
        snapshot.podsSection.value.map { max(0, $0.total - $0.ready) }
    }

    private func staleBanner(
        for state: ClusterHealthState,
        snapshot: ClusterSnapshot,
        failureReason: String?,
        now: Date
    ) -> StaleBannerDisplay? {
        guard state == .stale else {
            return nil
        }

        return StaleBannerDisplay(
            lastUpdated: relativeAge(from: snapshot.capturedAt, to: now),
            reason: failureReason ?? "Refresh failed"
        )
    }

    private func relativeAge(from date: Date, to now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))

        if seconds < 60 {
            return "\(seconds)s ago"
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m ago"
        }

        return "\(minutes / 60)h ago"
    }

    private func shortenedWarningMessage(_ value: String?) -> String? {
        shortenedText(value)
    }

    private func shortenedText(_ value: String?) -> String? {
        guard let value = normalizedText(value) else {
            return nil
        }

        guard value.count > warningMessageLimit else {
            return value
        }

        let prefixLimit = max(1, warningMessageLimit - 3)
        return String(value.prefix(prefixLimit)) + "..."
    }

    private func normalizedText(_ value: String?) -> String? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, !text.isEmpty else {
            return nil
        }

        return text
    }
}

private struct WarningEventGroupKey: Hashable, Sendable {
    let reason: String
    let objectKind: String?
    let namespace: String?
    let objectName: String?

    init(event: WarningEventRecord) {
        self.reason = event.reason
        self.objectKind = event.objectKind
        self.namespace = event.namespace
        self.objectName = event.objectName
    }

    var id: String {
        [reason, objectKind, namespace, objectName]
            .map { $0 ?? "-" }
            .joined(separator: "|")
    }
}

private struct WarningEventGroup: Sendable {
    let key: WarningEventGroupKey
    let reason: String
    private(set) var observedAt: Date?
    private(set) var occurrenceCount = 0
    private(set) var message: String?
    private var messageObservedAt: Date?

    init(key: WarningEventGroupKey, reason: String) {
        self.key = key
        self.reason = reason
    }

    mutating func add(_ event: WarningEventRecord, message: String?) {
        occurrenceCount += max(1, event.count)

        if let observedAt = event.observedAt {
            self.observedAt = max(self.observedAt ?? .distantPast, observedAt)
        }

        guard let message else {
            return
        }

        let eventObservedAt = event.observedAt ?? .distantPast
        if self.message == nil || eventObservedAt >= (messageObservedAt ?? .distantPast) {
            self.message = message
            self.messageObservedAt = eventObservedAt
        }
    }
}
