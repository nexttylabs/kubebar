# Phase 06: Polish Menu Bar Icon States and Keyboard Navigation - Pattern Map

**Mapped:** 2026-04-21
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `KubebarCore/Models/MenuBarStatusPresentation.swift` | model | transform | `KubebarCore/Models/MenuBarStatusPresentation.swift` | exact |
| `Kubebar/KubebarApp.swift` | provider | event-driven | `Kubebar/KubebarApp.swift` | exact |
| `KubebarCore/Models/MenuDisplayModel.swift` | model | transform | `KubebarCore/Models/MenuDisplayModel.swift` | exact |
| `KubebarCore/Services/HealthEvaluator.swift` | service | transform | `KubebarCore/Services/HealthEvaluator.swift` | exact |
| `Kubebar/Views/StatusSummaryView.swift` | component | transform | `Kubebar/Views/StatusSummaryView.swift` | exact |
| `Kubebar/Views/MenuBarRootView.swift` | component | event-driven | `Kubebar/Views/MenuBarRootView.swift` | exact |
| `Kubebar/Views/WatchlistSectionView.swift` | component | event-driven | `Kubebar/Views/WatchlistSectionView.swift` | exact |
| `Kubebar/Views/TrackedItemDetailView.swift` | component | transform | `Kubebar/Views/TrackedItemDetailView.swift` | exact |
| `Kubebar/Views/WarningEventsView.swift` | component | transform | `Kubebar/Views/WarningEventsView.swift` | exact |
| `Kubebar/Views/SetupView.swift` | component | event-driven | `Kubebar/Views/SetupView.swift` | exact |
| `Kubebar/Views/WatchlistPickerView.swift` | component | event-driven | `Kubebar/Views/WatchlistPickerView.swift` | exact |
| `KubebarTests/Models/MenuBarStatusPresentationTests.swift` | test | transform | `KubebarTests/Models/MenuBarStatusPresentationTests.swift` | exact |
| `KubebarTests/Models/MenuDisplayModelTests.swift` | test | transform | `KubebarTests/Models/MenuDisplayModelTests.swift` | exact |
| `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md` | test | event-driven | `.planning/phases/05-expand-kubectl-data-into-actionable-warning-and-workload-reasons/05-UAT.md` | role-match |
| `docs/architecture/runtime-invariants.md` | config | transform | `docs/architecture/runtime-invariants.md` | exact |

## Pattern Assignments

### `KubebarCore/Models/MenuBarStatusPresentation.swift` (model, transform)

**Analog:** `KubebarCore/Models/MenuBarStatusPresentation.swift`

**Imports pattern** (lines 1-7):
```swift
import Foundation

public struct MenuBarStatusPresentation: Equatable, Sendable {
    public enum IconSource: Equatable, Sendable {
        case system(String)
        case custom(String)
    }
```

**Core four-state icon pattern** (lines 15-25):
```swift
public var icon: IconSource {
    switch state {
    case .ok:
        .custom("KubebarLogo")
    case .watch:
        .system("exclamationmark.triangle")
    case .bad:
        .system("xmark.octagon")
    case .stale:
        .system("clock.badge.exclamationmark")
    }
}
```

**Accessibility pattern** (lines 41-43):
```swift
public var accessibilityLabel: String {
    "Kubebar \(state.label)"
}
```

**Planner note:** Keep `OK` as `.custom("KubebarLogo")`. Use `symbolName` only when a SwiftUI status summary needs a system symbol for the opened menu; do not change the menu bar `OK` label to a checkmark.

---

### `Kubebar/KubebarApp.swift` (provider, event-driven)

**Analog:** `Kubebar/KubebarApp.swift`

**Imports pattern** (lines 1-2):
```swift
import SwiftUI
import KubebarCore
```

**MenuBarExtra window shell pattern** (lines 9-33):
```swift
MenuBarExtra {
    MenuBarRootView(
        display: viewModel.display,
        setupState: $viewModel.setupState,
        isShowingSetup: viewModel.isShowingSetup,
        refreshCadence: viewModel.refreshCadence,
        isRefreshing: viewModel.isRefreshing,
        onRefresh: viewModel.refreshNow,
        onEditWatchlist: viewModel.openSetup,
        onCompleteSetup: viewModel.completeSetup,
        onSelectContext: viewModel.selectSetupContext,
        onSelectRefreshCadence: viewModel.selectRefreshCadence,
        onRetryTargets: viewModel.retryWatchTargetLoad
    )
} label: {
    let presentation = MenuBarStatusPresentation(state: viewModel.display.state)
    switch presentation.icon {
    case let .system(name):
        Label(presentation.accessibilityLabel, systemImage: name)
    case let .custom(name):
        Image(name)
            .accessibilityLabel(presentation.accessibilityLabel)
    }
}
.menuBarExtraStyle(.window)
```

**Planner note:** Copy this existing `MenuBarExtra.window` shape. Do not introduce `NSStatusItem`, `NSMenu`, provider registries, keychain/cookie providers, or CLI subproducts.

---

### `KubebarCore/Models/MenuDisplayModel.swift` (model, transform)

**Analog:** `KubebarCore/Models/MenuDisplayModel.swift`

**Display submodel pattern** (lines 9-39):
```swift
public struct WarningEventDisplay: Equatable, Sendable, Identifiable {
    public let id: String
    public let reason: String
    public let location: String
    public let age: String
    public let occurrenceCount: Int
    public let message: String?

    public var summary: String {
        if occurrenceCount > 1 {
            return "\(reason) x\(occurrenceCount) \(location) \(age)"
        }

        return "\(reason) \(location) \(age)"
    }
```

**Watch item display contract** (lines 76-95):
```swift
public struct WatchItemDisplay: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let state: ClusterHealthState
    public let reason: String
    public let detail: WatchItemDetailDisplay

    public init(
        id: String,
        title: String,
        state: ClusterHealthState,
        reason: String,
        detail: WatchItemDetailDisplay? = nil
    ) {
        self.id = id
        self.title = title
        self.state = state
        self.reason = reason
        self.detail = detail ?? WatchItemDetailDisplay(stateLabel: state.label, reason: reason)
    }
}
```

**Root display model pattern** (lines 103-137):
```swift
public struct MenuDisplayModel: Equatable, Sendable {
    public let state: ClusterHealthState
    public let contextName: String
    public let healthSentence: String
    public let lastUpdated: String
    public let counters: MenuCounters
    public let warningEventSummaries: [WarningEventDisplay]
    public let sectionNotices: [SectionAvailabilityDisplay]
    public let visibleWatchItems: [WatchItemDisplay]
    public let hiddenWatchItemCount: Int
    public let staleBanner: StaleBannerDisplay?

    public init(
        state: ClusterHealthState,
        contextName: String,
        healthSentence: String,
        lastUpdated: String,
        counters: MenuCounters,
        visibleWatchItems: [WatchItemDisplay],
        hiddenWatchItemCount: Int,
        staleBanner: StaleBannerDisplay?,
        warningEventSummaries: [WarningEventDisplay] = [],
        sectionNotices: [SectionAvailabilityDisplay] = []
    ) {
```

**Planner note:** Add new display-only fields here when the opened menu needs more presentation data, such as `primaryStatusReason` or full untruncated title fields. Do not make SwiftUI views infer health severity.

---

### `KubebarCore/Services/HealthEvaluator.swift` (service, transform)

**Analog:** `KubebarCore/Services/HealthEvaluator.swift`

**Imports and service shape** (lines 1-18):
```swift
import Foundation

public struct RefreshFailure: Equatable, Sendable {
    public let reason: String

    public init(reason: String) {
        self.reason = reason
    }
}

public struct HealthEvaluator: Sendable {
    private let visibleWatchItemLimit: Int
    private let warningEventSummaryLimit = 3
    private let warningMessageLimit = 96

    public init(visibleWatchItemLimit: Int = 5) {
        self.visibleWatchItemLimit = visibleWatchItemLimit
    }
```

**Evaluate entrypoint and stale fallback pattern** (lines 20-56):
```swift
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
```

**Display model assembly pattern** (lines 66-91):
```swift
let sortedItems = sortByAttention(snapshot.trackedItems)
let visibleItems = sortedItems.prefix(visibleWatchItemLimit).map { makeDisplayItem($0, now: now) }
let hiddenCount = max(0, sortedItems.count - visibleItems.count)
let freshnessReason = staleAgeOutReason(for: snapshot, now: now, staleAfterSeconds: staleAfterSeconds)
let resolvedState = stateOverride ?? (freshnessReason == nil ? evaluateState(snapshot) : .stale)
let warningEventSummaries = makeWarningEventSummaries(from: snapshot.warningEventsSection.value ?? [], now: now)
let sectionNotices = makeSectionNotices(from: snapshot.sectionFailures)
let lastUpdated = relativeAge(from: snapshot.capturedAt, to: now)

return MenuDisplayModel(
    state: resolvedState,
    contextName: snapshot.contextName,
    healthSentence: healthSentence(for: resolvedState, visibleItems: visibleItems),
    lastUpdated: lastUpdated,
    counters: menuCounters(from: snapshot),
    visibleWatchItems: Array(visibleItems),
```

**Severity source-of-truth pattern** (lines 103-117):
```swift
private func evaluateState(_ snapshot: ClusterSnapshot) -> ClusterHealthState {
    if snapshot.nodesSection.value.map({ $0.ready < $0.total }) == true ||
        snapshot.trackedItems.contains(where: { $0.state == .bad }) {
        return .bad
    }

    if snapshot.podsSection.value.map({ $0.running < $0.total }) == true ||
        snapshot.warningEventsSection.value.map({ !$0.isEmpty }) == true ||
        snapshot.trackedItems.contains(where: { $0.state == .watch }) ||
        !snapshot.sectionFailures.isEmpty {
        return .watch
    }

    return .ok
}
```

**Watch item mapping pattern** (lines 151-165):
```swift
private func makeDisplayItem(_ item: TrackedItemStatus, now: Date) -> WatchItemDisplay {
    WatchItemDisplay(
        id: item.target.displayTitle,
        title: shortened(item.target.displayTitle),
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
```

**Current truncation anti-pattern to replace** (lines 296-302):
```swift
private func shortened(_ value: String, limit: Int = 42) -> String {
    guard value.count > limit else {
        return value
    }

    return String(value.prefix(limit - 1)) + "…"
}
```

**Planner note:** Keep severity, primary reason selection, stale reason, watchlist ordering, and display contracts in `HealthEvaluator`. Replace tail pre-truncation with full-value display fields plus view-level one-line middle truncation.

---

### `Kubebar/Views/StatusSummaryView.swift` (component, transform)

**Analog:** `Kubebar/Views/StatusSummaryView.swift`

**Imports pattern** (lines 1-2):
```swift
import SwiftUI
import KubebarCore
```

**Render-only status summary pattern** (lines 7-23):
```swift
var body: some View {
    VStack(alignment: .leading, spacing: 4) {
        HStack {
            Text(display.contextName)
                .font(.headline)
                .lineLimit(1)

            Spacer()

            Text(display.state.label)
                .font(.caption.weight(.semibold))
        }

        Text(display.healthSentence)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}
```

**Planner note:** Keep this view render-only. For Phase 06, add the opened-menu symbol, explicit `OK`/`Watch`/`Bad`/`Stale` text, one primary reason, middle truncation, tooltip, and accessibility label here using fields supplied by `MenuDisplayModel`.

---

### `Kubebar/Views/MenuBarRootView.swift` (component, event-driven)

**Analog:** `Kubebar/Views/MenuBarRootView.swift`

**Setup vs menu branch pattern** (lines 17-35):
```swift
var body: some View {
    Group {
        if isShowingSetup {
            SetupView(
                state: $setupState,
                onComplete: onCompleteSetup,
                onSelectContext: onSelectContext,
                onRetryTargets: onRetryTargets
            )
                .frame(
                    width: Layout.setupWidth,
                    height: Layout.setupHeight,
                    alignment: .topLeading
                )
        } else {
            menuContent
        }
    }
}
```

**Watchlist-first menu order pattern** (lines 37-50):
```swift
private var menuContent: some View {
    VStack(alignment: .leading, spacing: 14) {
        StatusSummaryView(display: display)
        StaleBannerView(banner: display.staleBanner)
        CompactCountersView(counters: display.counters)
        WatchlistSectionView(display: display)
        WarningEventsView(count: display.counters.warningEvents, summaries: display.warningEventSummaries, sectionNotices: display.sectionNotices)
        NodeDetailsView(summary: display.counters.nodes)
        Divider()
        refreshControls
        actions
    }
    .frame(width: 340)
    .padding(16)
}
```

**Native controls and bindings pattern** (lines 53-84):
```swift
private var refreshControls: some View {
    HStack(spacing: 8) {
        Text("Refresh")
            .font(.caption)
            .foregroundStyle(.secondary)

        Picker("Refresh cadence", selection: refreshCadenceBinding) {
            ForEach(RefreshCadence.allCases) { cadence in
                Text(cadence.label).tag(cadence)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .frame(width: 96)
```

```swift
private var actions: some View {
    HStack {
        Button("Retry now", action: onRefresh)
            .disabled(isRefreshing)
        Spacer()
        Button("Edit watchlist", action: onEditWatchlist)
    }
}
```

**Planner note:** Preserve the order: summary, stale signal, counters, watchlist, warning events, node details, refresh, actions. Keyboard work should stay on native controls and targeted shortcuts, not custom key handling.

---

### `Kubebar/Views/WatchlistSectionView.swift` (component, event-driven)

**Analog:** `Kubebar/Views/WatchlistSectionView.swift`

**Watchlist-first disclosure pattern** (lines 7-31):
```swift
var body: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("Watchlist")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

        if display.visibleWatchItems.isEmpty {
            Text("No tracked workloads yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            ForEach(display.visibleWatchItems) { item in
                DisclosureGroup {
                    TrackedItemDetailView(item: item)
                } label: {
                    WatchlistRowView(item: item)
                }
            }
        }
```

**One-line row pattern** (lines 36-55):
```swift
private struct WatchlistRowView: View {
    let item: WatchItemDisplay

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .lineLimit(1)
                Text(item.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(item.state.label)
                .font(.caption.weight(.semibold))
        }
    }
}
```

**Planner note:** Keep rows one-line on the primary surface. Add `.truncationMode(.middle)`, `.help(Text(fullValue))`, and `.accessibilityLabel(fullValue)` once full title fields exist.

---

### `Kubebar/Views/TrackedItemDetailView.swift` (component, transform)

**Analog:** `Kubebar/Views/TrackedItemDetailView.swift`

**Detail render pattern** (lines 7-31):
```swift
var body: some View {
    VStack(alignment: .leading, spacing: 4) {
        Text("State: \(item.detail.stateLabel)")
        Text(item.detail.reason)

        if let affectedPodCount = item.detail.affectedPodCount {
            Text("Affected pods: \(affectedPodCount)")
        }

        if !item.detail.examplePodNames.isEmpty {
            Text("Examples: \(item.detail.examplePodNames.joined(separator: ", "))")
        }

        if let latestWarning = item.detail.latestWarning {
            Text("Latest warning: \(latestWarning.summary)")

            if let message = latestWarning.message {
                Text(message)
                    .lineLimit(2)
            }
        }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.leading, 6)
}
```

**Planner note:** Keep detail short. It may expose full names or tooltips, but it must not become a troubleshooting panel or deep handoff.

---

### `Kubebar/Views/WarningEventsView.swift` (component, transform)

**Analog:** `Kubebar/Views/WarningEventsView.swift`

**Secondary warning section pattern** (lines 9-40):
```swift
var body: some View {
    VStack(alignment: .leading, spacing: 4) {
        Text("Warning events")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

        ForEach(sectionNotices) { notice in
            Text("\(notice.title) unavailable: \(notice.reason)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        if summaries.isEmpty {
            Text(count == "0" ? "No current warning events" : "\(count) warning events need review")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(summaries) { summary in
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.summary)
                        .lineLimit(1)

                    if let message = summary.message {
                        Text(message)
                            .lineLimit(2)
                    }
```

**Planner note:** Keep warning events below the watchlist and capped by display data. Add middle truncation/help/accessibility to `summary.summary` or its future split fields without promoting warning events above watchlist rows.

---

### `Kubebar/Views/SetupView.swift` (component, event-driven)

**Analog:** `Kubebar/Views/SetupView.swift`

**Scrollable native setup layout pattern** (lines 22-33):
```swift
var body: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            header
            contextPicker
            watchlistPicker
            refreshCadencePicker
            footer
        }
        .padding(20)
        .frame(maxWidth: 560, alignment: .leading)
    }
}
```

**Context picker pattern** (lines 47-71):
```swift
private var contextPicker: some View {
    VStack(alignment: .leading, spacing: 10) {
        Text("Cluster context")
            .font(.headline)

        Text(state.contextHelpText)
            .font(.caption)
            .foregroundStyle(.secondary)

        if state.availableContexts.isEmpty {
            Text("No contexts available.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
        } else {
            Picker("Cluster context", selection: selectedContextBinding) {
                Text("Select a context").tag(Optional<String>.none)
                ForEach(state.availableContexts, id: \.self) { context in
                    Text(context).tag(Optional(context))
                }
            }
            .pickerStyle(.menu)
        }
```

**Footer action pattern** (lines 101-118):
```swift
private var footer: some View {
    HStack {
        if let configurationMessage = state.configurationMessage, !configurationMessage.isEmpty {
            Text(configurationMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text(state.watchlistHelpText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Spacer()

        Button("Finish setup", action: onComplete)
            .buttonStyle(.borderedProminent)
            .disabled(!state.isConfigured)
    }
}
```

**Binding pattern** (lines 121-133):
```swift
private var selectedContextBinding: Binding<String?> {
    Binding(
        get: { state.selectedContext },
        set: { onSelectContext($0) }
    )
}

private var watchlistBinding: Binding<WatchlistSelectionState> {
    Binding(
        get: { state.watchlist },
        set: { state.watchlist = $0 }
    )
}
```

**Planner note:** Apply middle truncation and tooltip/accessibility to context names in the picker. If adding keyboard shortcuts, prefer `.defaultAction` for `Finish setup` and keep standard keyboard traversal for the rest.

---

### `Kubebar/Views/WatchlistPickerView.swift` (component, event-driven)

**Analog:** `Kubebar/Views/WatchlistPickerView.swift`

**State-switch pattern** (lines 26-41):
```swift
@ViewBuilder
private var content: some View {
    switch loadingState {
    case .loading:
        loadingView
    case let .failed(reason):
        failureView(reason: reason)
    case .idle:
        if state.hasAvailableTargets {
            namespaceSection
            workloadSection
        } else {
            emptyTargetsView
        }
    }
}
```

**Native toggle and disclosure pattern** (lines 60-94):
```swift
private var namespaceSection: some View {
    SectionCard(
        title: "Namespaces",
        emptyTitle: "No namespaces yet",
        emptyMessage: "Namespaces keep the watchlist compact when you want whole areas of the cluster on the first screen.",
        hasItems: !state.availableNamespaces.isEmpty
    ) {
        ForEach(state.availableNamespaces, id: \.self) { namespace in
            Toggle(
                namespace,
                isOn: binding(for: .namespace(namespace))
            )
        }
    }
}

private var workloadSection: some View {
    SectionCard(
        title: "Workloads",
        emptyTitle: "No workloads yet",
        emptyMessage: "Watch individual workloads when one service needs regular attention.",
        hasItems: !state.availableWorkloads.isEmpty
    ) {
        ForEach(groupedWorkloads, id: \.key) { group in
            DisclosureGroup(group.key) {
                ForEach(group.value, id: \.self) { workload in
                    Toggle(
                        workload.displayTitle,
                        isOn: binding(for: workload.target)
```

**Recovery action pattern** (lines 109-135):
```swift
private func failureView(reason: String) -> some View {
    StateCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Could not load watch targets")
                .font(.subheadline.weight(.medium))

            Text(reason.isEmpty ? "Try loading targets again." : reason)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Retry", action: onRetryTargets)
        }
    }
}

private var emptyTargetsView: some View {
    StateCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("No watch targets found")
                .font(.subheadline.weight(.medium))
```

**Binding pattern** (lines 139-149):
```swift
private func binding(for target: WatchTarget) -> Binding<Bool> {
    Binding(
        get: { state.isSelected(target) },
        set: { state.setSelected(target, to: $0) }
    )
}

private var groupedWorkloads: [(key: String, value: [WatchlistCandidate])] {
    Dictionary(grouping: state.availableWorkloads, by: { $0.namespace })
        .sorted { $0.key < $1.key }
}
```

**Planner note:** Keyboard coverage should rely on these native controls. Add truncation/help/accessibility to namespace group labels and workload toggle labels; do not replace toggles with custom rows.

---

### `KubebarTests/Models/MenuBarStatusPresentationTests.swift` (test, transform)

**Analog:** `KubebarTests/Models/MenuBarStatusPresentationTests.swift`

**Imports and suite pattern** (lines 1-5):
```swift
import Testing
@testable import KubebarCore

@Suite("Menu bar status presentation")
struct MenuBarStatusPresentationTests {
```

**Four-state assertion pattern** (lines 6-17):
```swift
@Test("maps health states to distinct symbols and labels")
func mapsHealthStatesToDistinctSymbolsAndLabels() {
    #expect(MenuBarStatusPresentation(state: .ok).symbolName == "checkmark.circle")
    #expect(MenuBarStatusPresentation(state: .watch).symbolName == "exclamationmark.triangle")
    #expect(MenuBarStatusPresentation(state: .bad).symbolName == "xmark.octagon")
    #expect(MenuBarStatusPresentation(state: .stale).symbolName == "clock.badge.exclamationmark")

    #expect(MenuBarStatusPresentation(state: .ok).accessibilityLabel == "Kubebar OK")
    #expect(MenuBarStatusPresentation(state: .watch).accessibilityLabel == "Kubebar Watch")
    #expect(MenuBarStatusPresentation(state: .bad).accessibilityLabel == "Kubebar Bad")
    #expect(MenuBarStatusPresentation(state: .stale).accessibilityLabel == "Kubebar Stale")
}
```

**Planner note:** Extend this suite to assert `MenuBarStatusPresentation(state: .ok).icon == .custom("KubebarLogo")` and preserve the locked Watch/Bad/Stale symbols.

---

### `KubebarTests/Models/MenuDisplayModelTests.swift` (test, transform)

**Analog:** `KubebarTests/Models/MenuDisplayModelTests.swift`

**Imports and suite pattern** (lines 1-6):
```swift
import Foundation
import Testing
@testable import KubebarCore

@Suite("Menu display model")
struct MenuDisplayModelTests {
```

**Healthy state regression pattern** (lines 7-29):
```swift
@Test("healthy snapshots show OK status and compact counters")
func healthySnapshotShowsOKStatusAndCounters() {
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

    let display = HealthEvaluator().evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 120))

    #expect(display.state == .ok)
    #expect(display.contextName == "prod")
    #expect(display.counters.nodes == "3/3")
    #expect(display.counters.pods == "12/12")
    #expect(display.counters.warningEvents == "0")
    #expect(display.healthSentence == "Cluster looks healthy")
```

**Attention ordering pattern** (lines 31-51):
```swift
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
}
```

**Current truncation test to replace** (lines 73-93):
```swift
@Test("long watch item titles truncate consistently")
func longWatchItemTitlesTruncateConsistently() {
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

    #expect(display.visibleWatchItems.first?.title == "production-namespace/checkout-api-with-a-…")
}
```

**Stale fallback regression pattern** (lines 95-121):
```swift
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
```

**Warning and partial-section test pattern** (lines 185-205 and 298-314):
```swift
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
```

```swift
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
```

**Planner note:** Add deterministic tests for `primaryStatusReason` or equivalent across `OK`, `Watch`, `Bad`, and `Stale`. Replace tail-truncation assertions with full-name preservation and view-level truncation contract assertions.

---

### `.planning/phases/06-polish-menu-bar-icon-states-and-keyboard-navigation/06-UAT.md` (test, event-driven)

**Analog:** `.planning/phases/05-expand-kubectl-data-into-actionable-warning-and-workload-reasons/05-UAT.md`

**Front matter and test list pattern** (lines 1-16):
```markdown
---
status: partial
phase: 05-expand-kubectl-data-into-actionable-warning-and-workload-reasons
source:
  - 05-01-SUMMARY.md
  - 05-02-SUMMARY.md
  - 05-03-SUMMARY.md
started: 2026-04-21T09:50:49Z
updated: 2026-04-21T09:56:29Z
---

## Current Test

[testing paused - 3 items blocked by current live test conditions]

## Tests
```

**Per-check result pattern** (lines 18-55):
```markdown
### 1. Warning counter remains compact
expected: In the menu, warning events still appear as a compact counter. The counter should not turn into a long event list or raw kubectl output.
result: pass
evidence: "Debug app launched successfully. Live cluster returned warning events, and automated model/view checks preserve compact warning counters without raw kubectl output."

### 2. Warning section shows at most 3 summaries
expected: The Warning events section shows no more than 3 warning summaries even when the cluster has more warning groups.
result: pass
evidence: "Live cluster had more than 3 warning groups. MenuDisplayModelTests verified the three-row cap, and WarningEventsView renders only the prepared summaries."
```

**Manual tool limitation pattern** (lines 69-75):
```markdown
## Computer Use Notes

- Kubebar launched from `DerivedData/Build/Products/Debug/Kubebar.app`.
- Computer Use could read ordinary app windows such as Finder.
- Computer Use could not obtain an interactive state for `com.nextty.kubebar`, `SystemUIServer`, or `ControlCenter`, so the menu bar extra itself could not be directly inspected.
- The live app config watches namespace targets only: `arc-runners` and `dev`.
- The live cluster had 13 warning events and repeated `FailedScheduling` warnings, which is enough to support warning cap and grouping checks through the existing automated display tests.
```

**Checklist analog:** `.planning/phases/04-codexbar-inspired-menu-reliability-and-freshness/04-UAT.md` lines 24-46:
```markdown
## Checklist

| Test | Expected Result | Status |
| --- | --- | --- |
| Launch with `./scripts/compile-and-run.sh` | Kubebar process starts and PID is printed | passed: PID 16286 |
| Fresh config opens setup | Setup view is readable, not collapsed | pending |
| Context list loads | Context picker shows available Kubernetes contexts | pending |
| Select context | Watchlist target area loads namespace/workload choices | pending |
| Finish setup | Normal menu opens with watchlist-first content | pending |
```

**Planner note:** Phase 06 UAT must cover all four states, setup, edit watchlist, refresh enabled/disabled, watchlist detail disclosure, warning events, secondary sections, long-name tooltip/accessibility, and Full Keyboard Access. Keep blocked states explicit when live data cannot force a state.

---

### `docs/architecture/runtime-invariants.md` (config, transform)

**Analog:** `docs/architecture/runtime-invariants.md`

**Product and data invariant pattern** (lines 5-31):
```markdown
## Product Rules

- The menu bar icon only uses `OK`, `Watch`, `Bad`, or `Stale`.
- The first screen is watchlist-first.
- The first screen shows only a small set of tracked items, with overflow
  pushed behind a secondary entry.
- Deep troubleshooting stays out of version 1.

## Data Rules

- `MenuDisplayModel` is the only input the menu uses for rendering.
- `HealthEvaluator` is the single source of truth for severity.
- `AppConfigStore` owns the saved context and watchlist.
```

**Watchlist and failure invariant pattern** (lines 49-76):
```markdown
## Watchlist Rules

- Watchlist rows stay short and readable.
- Tracked item names may truncate, but their meaning should still be clear.
- The watchlist is ordered by attention, not by raw cluster size.
- An empty watchlist is a real state and must not be treated as a healthy
  cluster.
```

```markdown
## Failure Rules

- Timeout, command failure, malformed JSON, and no previous data are distinct
  safe reason categories.
- Timeout uses `kubectl timed out`.
- Empty or unsafe command failure output uses `kubectl failed`.
- Malformed section data uses short reasons such as `invalid node JSON`,
  `invalid pod JSON`, `invalid event JSON`, or `invalid workload JSON`.
- No previous successful data uses `No previous cluster data`.
- A refresh failure must never silently clear the last good data.
- Warning and failure states must not rely on color alone.
- Stale or failed reads must use distinct icon semantics from `OK`.
```

**Planner note:** If implementation changes user-visible invariants, update this doc with middle truncation, full-name fallback, explicit opened-menu state text, and keyboard/manual QA expectations. Do not add deep troubleshooting or `Open in k9s`.

## Shared Patterns

### Core Owns Health and Top Reason

**Source:** `docs/architecture/system-overview.md` lines 13-17 and `HealthEvaluator.swift` lines 103-117
**Apply to:** `MenuDisplayModel`, `HealthEvaluator`, `StatusSummaryView`, tests

```markdown
5. `KubebarCore/Services/HealthEvaluator.swift` turns the latest snapshot into a
   `MenuDisplayModel`.
6. `MenuDisplayModel` is the only shape the menu uses to render the screen.
```

```swift
private func evaluateState(_ snapshot: ClusterSnapshot) -> ClusterHealthState {
    if snapshot.nodesSection.value.map({ $0.ready < $0.total }) == true ||
        snapshot.trackedItems.contains(where: { $0.state == .bad }) {
        return .bad
    }
```

### Views Render `MenuDisplayModel` Only

**Source:** `docs/architecture/system-overview.md` lines 37-60
**Apply to:** all SwiftUI menu views

```markdown
The menu never asks Kubernetes directly. It reads a display model that already
includes:

- the selected context name,
- the health sentence,
- compact node, pod, and warning counts,
- visible watchlist rows,
- overflow count for hidden watched items,
- stale banner content when the last refresh is no longer fresh.
```

```markdown
The menu is allowed to show state and actions. It is not allowed to:

- decide cluster health on its own,
- read raw `kubectl` output,
- infer the terminal context,
- expand into a troubleshooting console.
```

### Watchlist-First Ordering

**Source:** `Kubebar/Views/MenuBarRootView.swift` lines 37-50
**Apply to:** `MenuBarRootView`, `WatchlistSectionView`, `WarningEventsView`, `NodeDetailsView`

```swift
VStack(alignment: .leading, spacing: 14) {
    StatusSummaryView(display: display)
    StaleBannerView(banner: display.staleBanner)
    CompactCountersView(counters: display.counters)
    WatchlistSectionView(display: display)
    WarningEventsView(count: display.counters.warningEvents, summaries: display.warningEventSummaries, sectionNotices: display.sectionNotices)
    NodeDetailsView(summary: display.counters.nodes)
```

### Native Keyboard-Reachable Controls

**Source:** `MenuBarRootView.swift` lines 59-83, `SetupView.swift` lines 92-118, `WatchlistPickerView.swift` lines 83-90 and 119-135
**Apply to:** refresh, edit watchlist, setup, retry, watchlist picker, details

```swift
Picker("Refresh cadence", selection: refreshCadenceBinding) {
    ForEach(RefreshCadence.allCases) { cadence in
        Text(cadence.label).tag(cadence)
    }
}
.labelsHidden()
.pickerStyle(.menu)
```

```swift
Button("Finish setup", action: onComplete)
    .buttonStyle(.borderedProminent)
    .disabled(!state.isConfigured)
```

```swift
DisclosureGroup(group.key) {
    ForEach(group.value, id: \.self) { workload in
        Toggle(
            workload.displayTitle,
            isOn: binding(for: workload.target)
        )
    }
}
```

### One-Line Text Base Pattern

**Source:** `StatusSummaryView.swift` lines 10-12, `WatchlistSectionView.swift` lines 42-47, `WarningEventsView.swift` lines 28-33
**Apply to:** context names, namespace names, workload names, warning locations, row reasons

```swift
Text(display.contextName)
    .font(.headline)
    .lineLimit(1)
```

```swift
Text(item.title)
    .lineLimit(1)
Text(item.reason)
    .font(.caption)
    .foregroundStyle(.secondary)
    .lineLimit(1)
```

```swift
Text(summary.summary)
    .lineLimit(1)

if let message = summary.message {
    Text(message)
        .lineLimit(2)
}
```

**Research supplement:** No local file currently uses `.truncationMode(.middle)` or `.help(Text(...))`. Apply the SwiftUI pattern from `06-RESEARCH.md` when adding Phase 06 truncation:

```swift
Text(fullName)
    .lineLimit(1)
    .truncationMode(.middle)
    .help(Text(fullName))
    .accessibilityLabel(fullName)
```

### Swift Testing Regression Style

**Source:** `KubebarTests/Models/MenuDisplayModelTests.swift` lines 7-29 and `MenuBarStatusPresentationTests.swift` lines 6-17
**Apply to:** state icon tests, top reason tests, full-name preservation tests

```swift
@Test("healthy snapshots show OK status and compact counters")
func healthySnapshotShowsOKStatusAndCounters() {
    let snapshot = ClusterSnapshot(
        contextName: "prod",
        nodeSummary: NodeSummary(ready: 3, total: 3),
        podSummary: PodSummary(running: 12, total: 12),
        warningEventCount: 0,
```

```swift
#expect(MenuBarStatusPresentation(state: .ok).accessibilityLabel == "Kubebar OK")
#expect(MenuBarStatusPresentation(state: .watch).accessibilityLabel == "Kubebar Watch")
#expect(MenuBarStatusPresentation(state: .bad).accessibilityLabel == "Kubebar Bad")
#expect(MenuBarStatusPresentation(state: .stale).accessibilityLabel == "Kubebar Stale")
```

## No Analog Found

All target files have a local analog. The only missing local usage is the exact SwiftUI middle-truncation/help modifier combination; use the `06-RESEARCH.md` SwiftUI docs pattern above and keep the data contract in `MenuDisplayModel`.

## Metadata

**Analog search scope:** `Kubebar/`, `KubebarCore/`, `KubebarTests/`, `docs/architecture/`, `.planning/phases/03-*`, `.planning/phases/04-*`, `.planning/phases/05-*`
**Files scanned:** 123 Swift, Markdown, asset metadata, and planning files via `rg --files` and targeted `rg`
**Pattern extraction date:** 2026-04-21
**Project constraints applied:** watchlist-first, `MenuBarExtra.window`, no AppKit `NSStatusItem` migration, no dashboard sprawl, no deep troubleshooting handoff
