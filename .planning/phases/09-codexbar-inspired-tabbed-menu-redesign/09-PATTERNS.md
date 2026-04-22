# Phase 09: CodexBar-Inspired Tabbed Menu Redesign - Pattern Map

**Mapped:** 2026-04-22
**Files analyzed:** 18 likely new/modified files
**Analogs found:** 16 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Kubebar/KubebarApp.swift` | app shell | event-driven | `Kubebar/KubebarApp.swift` | exact |
| `Kubebar/MenuBarViewModel.swift` | view model | event-driven + request-response | `Kubebar/MenuBarViewModel.swift` | exact |
| `Kubebar/Views/MenuBarRootView.swift` | component/root | event-driven + transform | `Kubebar/Views/MenuBarRootView.swift` | exact |
| `Kubebar/Views/MenuTab.swift` | model/UI state | event-driven | `KubebarCore/Models/MenuRuntimeState.swift` | role-match |
| `Kubebar/Views/OverviewTabView.swift` | component | transform | `Kubebar/Views/MenuBarRootView.swift` | role-match |
| `Kubebar/Views/NodesTabView.swift` | component | transform | `Kubebar/Views/NodeDetailsView.swift` | exact |
| `Kubebar/Views/PodsTabView.swift` | component | transform | `Kubebar/Views/WatchlistSectionView.swift` | exact |
| `Kubebar/Views/EventsTabView.swift` | component | transform | `Kubebar/Views/WarningEventsView.swift` | exact |
| `Kubebar/Views/MenuFooterView.swift` | component | event-driven | `Kubebar/Views/MenuBarRootView.swift` | exact |
| `Kubebar/Views/SettingsRootView.swift` | component | config CRUD | `Kubebar/Views/SetupView.swift` | role-match |
| `Kubebar/Views/SetupView.swift` | component | config CRUD | `Kubebar/Views/SetupView.swift` | exact |
| `Kubebar/Views/WatchlistSectionView.swift` | component | transform | `Kubebar/Views/WatchlistSectionView.swift` | exact |
| `Kubebar/Views/WarningEventsView.swift` | component | transform | `Kubebar/Views/WarningEventsView.swift` | exact |
| `KubebarCore/Models/MenuDisplayModel.swift` | model | transform | `KubebarCore/Models/MenuDisplayModel.swift` | exact |
| `KubebarCore/Services/HealthEvaluator.swift` | service | transform | `KubebarCore/Services/HealthEvaluator.swift` | exact |
| `KubebarTests/Models/MenuDisplayModelTests.swift` | test | transform | `KubebarTests/Models/MenuDisplayModelTests.swift` | exact |
| `KubebarTests/Models/MenuTabStateTests.swift` | test | event-driven | `KubebarTests/Models/MenuRuntimeStateTests.swift` | role-match |
| `.planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-UAT.md` | test/manual validation | manual event-driven | `.planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-VALIDATION.md` | role-match |

## Pattern Assignments

### `Kubebar/KubebarApp.swift` (app shell, event-driven)

**Analog:** `Kubebar/KubebarApp.swift`

**Imports pattern** (lines 1-2):
```swift
import SwiftUI
import KubebarCore
```

**MenuBarExtra.window shell pattern** (lines 4-34):
```swift
@main
struct KubebarApp: App {
    @StateObject private var viewModel = MenuBarViewModel()

    var body: some Scene {
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
    }
}
```

**Apply to Phase 09:**
- Keep `MenuBarExtra` and `.menuBarExtraStyle(.window)`.
- Continue deriving the menu bar icon from `MenuBarStatusPresentation(state:)`.
- Add Settings/Quit wiring at app shell level, not inside `KubebarCore`.
- There is no existing local `Settings` scene or app quit analog. Use research fallback for SwiftUI `Settings` scene / `openSettings` and AppKit `NSApplication.shared.terminate(nil)`.

---

### `Kubebar/MenuBarViewModel.swift` (view model, event-driven + request-response)

**Analog:** `Kubebar/MenuBarViewModel.swift`

**State ownership pattern** (lines 5-34):
```swift
@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published private(set) var display: MenuDisplayModel
    @Published var setupState: SetupFlowState {
        didSet {
            guard !isPublishingRuntimeState else {
                return
            }

            runtimeState.setupState = setupState
            refreshCadence = setupState.refreshCadence
        }
    }
    @Published private(set) var isShowingSetup: Bool
    @Published private(set) var refreshCadence: RefreshCadence
    @Published private(set) var isRefreshing: Bool

    private let configStore: AppConfigStore
    private let refreshCoordinator: RefreshCoordinator
    private let contextCatalog: ContextCatalog
    private let watchTargetCatalog: any WatchTargetCataloging
    private var config: AppConfig
    private var snapshot: ClusterSnapshot?
    private var runtimeState: MenuRuntimeState
```

**Refresh action pattern** (lines 84-123):
```swift
func refreshNow() {
    performRefresh(queueIfBusy: false)
}

private func performRefresh(queueIfBusy: Bool) {
    updateFreshnessDisplay()

    guard let ticket = refreshGate.begin(config: config) else {
        if queueIfBusy {
            refreshGate.requestPendingRefresh()
        }
        return
    }

    isRefreshing = true
    let config = config
    let previousSnapshot = snapshot
    let refreshCoordinator = refreshCoordinator

    Task {
        defer {
            let shouldRunPendingRefresh = refreshGate.finishAndConsumePendingRefresh()
            isRefreshing = false

            if shouldRunPendingRefresh {
                performRefresh(queueIfBusy: false)
            }
        }

        let result = await Task.detached(priority: .userInitiated) {
            refreshCoordinator.refresh(config: config, previousSnapshot: previousSnapshot, now: Date())
        }.value

        guard refreshGate.shouldApply(ticket, currentConfig: self.config) else {
            return
        }

        applyRefreshResult(result)
    }
}
```

**Setup/settings save pattern** (lines 125-153):
```swift
func openSetup() {
    runtimeState.openSetup()
    publishRuntimeState()
    loadContextsIfNeeded()

    if let selectedContext = runtimeState.targetContextToLoad {
        loadWatchTargets(for: selectedContext)
    }
}

func completeSetup() {
    guard let completedConfig = runtimeState.completedConfig() else {
        return
    }

    config = completedConfig

    do {
        try configStore.save(config)
        invalidateRefreshState(clearSnapshot: true)
        display = Self.initialDisplay(for: config, now: Date())
        runtimeState.completeSetupSaved()
        publishRuntimeState()
        performRefresh(queueIfBusy: true)
        startRefreshLoopIfConfigured()
    } catch {
        runtimeState.markConfigurationSaveFailed("Could not save setup. Try again.")
        publishRuntimeState()
    }
}
```

**Apply to Phase 09:**
- Keep tab selection out of persisted config. If extracted, it should be UI-local state or a small value type.
- Reuse `openSetup()` / `completeSetup()` semantics for independent Settings unless the planner explicitly splits first-use from edit mode.
- Settings edits must continue to save through `AppConfigStore`; Quit must not call config mutation methods.

---

### `Kubebar/Views/MenuBarRootView.swift` (component/root, event-driven + transform)

**Analog:** `Kubebar/Views/MenuBarRootView.swift`

**Composition root pattern** (lines 4-16):
```swift
struct MenuBarRootView: View {
    let display: MenuDisplayModel
    @Binding var setupState: SetupFlowState
    let isShowingSetup: Bool
    let refreshCadence: RefreshCadence
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onEditWatchlist: () -> Void
    let onCompleteSetup: () -> Void
    let onSelectContext: (String?) -> Void
    let onSelectRefreshCadence: (RefreshCadence) -> Void
    let onRetryTargets: () -> Void
```

**Current menu content to reorganize into tabs** (lines 37-51):
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

**Footer action pattern** (lines 53-88):
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

        Text("Last updated \(display.lastUpdated)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

        Spacer()
    }
}

private var actions: some View {
    HStack {
        Button("Retry now", action: onRefresh)
            .keyboardShortcut("r", modifiers: .command)
            .help(Text(isRefreshing ? "Refresh in progress" : "Refresh now"))
            .disabled(isRefreshing)
        Spacer()
        Button("Edit watchlist", action: onEditWatchlist)
            .keyboardShortcut("e", modifiers: .command)
            .help(Text("Edit watchlist"))
    }
}
```

**Apply to Phase 09:**
- Replace single vertical body with tab control plus selected tab content.
- Preserve `StatusSummaryView`, `StaleBannerView`, `CompactCountersView`, `WatchlistSectionView`, `WarningEventsView`, and `NodeDetailsView` as tab content building blocks.
- Convert `Edit watchlist` to `Settings...` and add a visible `Quit Kubebar` footer action.
- Keep `Retry now` disabled while refreshing and keep Command-R.

---

### `Kubebar/Views/MenuTab.swift` (model/UI state, event-driven)

**Analog:** `KubebarCore/Models/MenuRuntimeState.swift`

**Enum/state pattern** (lines 3-10):
```swift
public enum MenuSurface: Equatable, Sendable {
    case setup
    case menu
}

public struct MenuRuntimeState: Equatable, Sendable {
    public private(set) var surface: MenuSurface
    public var setupState: SetupFlowState
```

**State transition pattern** (lines 37-40, 91-94):
```swift
public mutating func openSetup() {
    surface = .setup
    setupState.configurationMessage = nil
}

public mutating func completeSetupSaved() {
    surface = .menu
    setupState.configurationMessage = nil
}
```

**Apply to Phase 09:**
- If the tab list is extracted, use a small exhaustive enum with cases equivalent to `overview`, `nodes`, `pods`, `events`.
- Keep it `Equatable` and `Sendable` if it crosses tests or view-model boundaries.
- Do not add Settings as a case.
- Do not persist selected tab in `AppConfig`.

---

### `Kubebar/Views/OverviewTabView.swift` (component, transform)

**Analog:** `Kubebar/Views/MenuBarRootView.swift`

**Core Overview content pattern** (lines 37-45):
```swift
VStack(alignment: .leading, spacing: 14) {
    StatusSummaryView(display: display)
    StaleBannerView(banner: display.staleBanner)
    CompactCountersView(counters: display.counters)
    WatchlistSectionView(display: display)
    WarningEventsView(count: display.counters.warningEvents, summaries: display.warningEventSummaries, sectionNotices: display.sectionNotices)
    NodeDetailsView(summary: display.counters.nodes)
    Divider()
```

**Status accessibility pattern** from `StatusSummaryView.swift` (lines 11-31):
```swift
VStack(alignment: .leading, spacing: 4) {
    Text(display.contextName)
        .font(.headline)
        .lineLimit(1)
        .truncationMode(.middle)
        .help(Text(display.contextName))
        .accessibilityLabel(display.contextName)

    HStack(spacing: 6) {
        Image(systemName: presentation.symbolName)
        Text(display.state.label)
            .fontWeight(.semibold)
        Text(display.primaryStatusReason)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
    .font(.subheadline)
}
.accessibilityElement(children: .ignore)
.accessibilityLabel("\(presentation.accessibilityLabel), \(display.primaryStatusReason), context \(display.contextName)")
```

**Apply to Phase 09:**
- Overview should keep status, stale banner, counters, watchlist, and one compact event/section notice.
- If Overview needs a smaller warning summary than Events, prefer a dedicated display-model field if copy/cap differs; otherwise a simple view-level `prefix(1)` is acceptable only when it remains purely presentational.

---

### `Kubebar/Views/NodesTabView.swift` (component, transform)

**Analog:** `Kubebar/Views/NodeDetailsView.swift`

**Node summary pattern** (lines 3-19):
```swift
struct NodeDetailsView: View {
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Node details")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("\(summary) nodes ready")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Node details, \(summary) nodes ready")
        .focusable()
    }
}
```

**Apply to Phase 09:**
- Start with aggregate readiness from `display.counters.nodes`.
- For unavailable or unknown node states, use `MenuDisplayModel.sectionNotices`; do not infer health from raw strings in the view.
- If richer node rows are added, shape them in `KubebarCore/Models/MenuDisplayModel.swift` and map them in `HealthEvaluator.swift`.

---

### `Kubebar/Views/PodsTabView.swift` (component, transform)

**Analog:** `Kubebar/Views/WatchlistSectionView.swift` and `Kubebar/Views/TrackedItemDetailView.swift`

**Watchlist row and disclosure pattern** from `WatchlistSectionView.swift` (lines 13-27, 39-60):
```swift
if display.visibleWatchItems.isEmpty {
    Text("No tracked workloads yet")
        .font(.subheadline)
        .foregroundStyle(.secondary)
} else {
    ForEach(display.visibleWatchItems) { item in
        DisclosureGroup(
            content: {
                TrackedItemDetailView(item: item)
            },
            label: {
                WatchlistRowView(item: item)
            }
        )
    }
}

private struct WatchlistRowView: View {
    let item: WatchItemDisplay

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(item.title))
                    .accessibilityLabel(item.title)
                Text(item.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
```

**Pod detail pattern** from `TrackedItemDetailView.swift` (lines 7-44):
```swift
VStack(alignment: .leading, spacing: 4) {
    Text("State: \(item.detail.stateLabel)")
    Text(item.detail.reason)

    if let affectedPodCount = item.detail.affectedPodCount {
        Text("Affected pods: \(affectedPodCount)")
    }

    if !item.detail.examplePodNames.isEmpty {
        let examples = "Examples: \(item.detail.examplePodNames.joined(separator: ", "))"
        Text(examples)
            .lineLimit(1)
            .truncationMode(.middle)
            .help(Text(examples))
            .accessibilityLabel(examples)
    }

    if let latestWarning = item.detail.latestWarning {
        let latestWarningSummary = "Latest warning: \(latestWarning.summary)"
        Text(latestWarningSummary)
            .lineLimit(1)
            .truncationMode(.middle)
            .help(Text(latestWarningSummary))
            .accessibilityLabel(latestWarningSummary)
```

**Apply to Phase 09:**
- Reuse `WatchItemDisplay.detail` for affected pod count and up to 3 example pod names.
- Do not add all-namespace pod inventory in the view.
- Preserve middle truncation, help text, and accessibility labels for pod/workload names.

---

### `Kubebar/Views/EventsTabView.swift` (component, transform)

**Analog:** `Kubebar/Views/WarningEventsView.swift`

**Event list pattern** (lines 4-54):
```swift
struct WarningEventsView: View {
    let count: String
    let summaries: [WarningEventDisplay]
    let sectionNotices: [SectionAvailabilityDisplay]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Warning events")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(sectionNotices) { notice in
                let noticeText = "\(notice.title) unavailable: \(notice.reason)"
                Text(noticeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(noticeText))
                    .accessibilityLabel(noticeText)
            }

            if summaries.isEmpty, let emptySummaryText {
                Text(emptySummaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(summaries) { summary in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary.summary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(Text(summary.summary))
                            .accessibilityLabel(summary.summary)
```

**Empty/accessibility pattern** (lines 56-87):
```swift
private var emptySummaryText: String? {
    switch count {
    case "0":
        return "No current warning events"
    case "1":
        return "1 warning event needs review"
    case "-":
        return sectionNotices.isEmpty ? "Warning event count unavailable" : nil
    default:
        return "\(count) warning events need review"
    }
}

private var accessibilitySummary: String {
    var parts = ["Warning events"]
    parts += sectionNotices.map { "\($0.title) unavailable: \($0.reason)" }
```

**Apply to Phase 09:**
- Events tab should reuse grouped warning rows from `display.warningEventSummaries`.
- Keep event rows capped by `HealthEvaluator` unless Phase 09 explicitly adds separate Overview/Event caps in `MenuDisplayModel`.
- Preserve `.focusable()` and combined accessibility summary.

---

### `Kubebar/Views/MenuFooterView.swift` (component, event-driven)

**Analog:** `Kubebar/Views/MenuBarRootView.swift`

**Refresh cadence binding pattern** (lines 90-95):
```swift
private var refreshCadenceBinding: Binding<RefreshCadence> {
    Binding(
        get: { refreshCadence },
        set: { onSelectRefreshCadence($0) }
    )
}
```

**Button/shortcut pattern** (lines 77-87):
```swift
private var actions: some View {
    HStack {
        Button("Retry now", action: onRefresh)
            .keyboardShortcut("r", modifiers: .command)
            .help(Text(isRefreshing ? "Refresh in progress" : "Refresh now"))
            .disabled(isRefreshing)
        Spacer()
        Button("Edit watchlist", action: onEditWatchlist)
            .keyboardShortcut("e", modifiers: .command)
            .help(Text("Edit watchlist"))
    }
}
```

**Apply to Phase 09:**
- Keep `Retry now` action style and disabled behavior.
- Replace `Edit watchlist` with `Settings...`.
- Add `Quit Kubebar` as a visible footer action separated by spacing or divider.
- There is no local quit analog; use `NSApplication.shared.terminate(nil)` from research fallback and do not mutate config.

---

### `Kubebar/Views/SettingsRootView.swift` and `Kubebar/Views/SetupView.swift` (component, config CRUD)

**Analog:** `Kubebar/Views/SetupView.swift` and `Kubebar/Views/WatchlistPickerView.swift`

**Setup root pattern** from `SetupView.swift` (lines 4-34):
```swift
struct SetupView: View {
    @Binding var state: SetupFlowState
    let onComplete: () -> Void
    let onSelectContext: (String?) -> Void
    let onRetryTargets: () -> Void

    init(
        state: Binding<SetupFlowState>,
        onComplete: @escaping () -> Void = {},
        onSelectContext: @escaping (String?) -> Void = { _ in },
        onRetryTargets: @escaping () -> Void = {}
    ) {
        _state = state
        self.onComplete = onComplete
        self.onSelectContext = onSelectContext
        self.onRetryTargets = onRetryTargets
    }

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

**Context picker truncation/accessibility pattern** from `SetupView.swift` (lines 64-75):
```swift
Picker("Cluster context", selection: selectedContextBinding) {
    Text("Select a context").tag(Optional<String>.none)
    ForEach(state.availableContexts, id: \.self) { context in
        Text(context)
            .lineLimit(1)
            .truncationMode(.middle)
            .help(Text(context))
            .accessibilityLabel(context)
            .tag(Optional(context))
    }
}
.pickerStyle(.menu)
```

**Watchlist loading/failure pattern** from `WatchlistPickerView.swift` (lines 26-40, 124-139):
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

private func failureView(reason: String) -> some View {
    StateCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Could not load watch targets")
                .font(.subheadline.weight(.medium))

            Text(reason.isEmpty ? "Try loading targets again." : reason)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Retry", action: onRetryTargets)
                .keyboardShortcut("r", modifiers: .command)
                .help(Text("Retry loading watch targets"))
        }
    }
}
```

**Apply to Phase 09:**
- Move this surface behind independent Settings. Do not keep full setup as the normal menu body.
- Preserve 560pt baseline from `SetupView`; UI spec allows 560pt by 560pt and up to 620pt width if needed.
- If editing existing settings, add a parameter or state-derived copy so the primary CTA can say `Save Settings`; first-use keeps `Finish setup`.
- Preserve retry/loading/recovery behavior.

---

### `KubebarCore/Models/MenuDisplayModel.swift` (model, transform)

**Analog:** `KubebarCore/Models/MenuDisplayModel.swift`

**Display value-type pattern** (lines 3-7, 9-40, 64-74):
```swift
public struct MenuCounters: Equatable, Sendable {
    public let nodes: String
    public let pods: String
    public let warningEvents: String
}

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
}

public struct SectionAvailabilityDisplay: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let reason: String
}
```

**Menu render contract pattern** (lines 103-140):
```swift
public struct MenuDisplayModel: Equatable, Sendable {
    public let state: ClusterHealthState
    public let contextName: String
    public let healthSentence: String
    public let primaryStatusReason: String
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
        primaryStatusReason: String? = nil,
        lastUpdated: String,
        counters: MenuCounters,
        visibleWatchItems: [WatchItemDisplay],
        hiddenWatchItemCount: Int,
        staleBanner: StaleBannerDisplay?,
        warningEventSummaries: [WarningEventDisplay] = [],
        sectionNotices: [SectionAvailabilityDisplay] = []
    ) {
```

**Apply to Phase 09:**
- Add new tab-specific display fields here only if existing `counters`, `warningEventSummaries`, `sectionNotices`, and `visibleWatchItems` cannot express explicit empty/unavailable/stale states.
- Keep new structs `Equatable`, `Sendable`, and `Identifiable` when rendered by `ForEach`.
- Keep SwiftUI/AppKit out of `KubebarCore`.

---

### `KubebarCore/Services/HealthEvaluator.swift` (service, transform)

**Analog:** `KubebarCore/Services/HealthEvaluator.swift`

**Evaluator construction and limits pattern** (lines 11-18):
```swift
public struct HealthEvaluator: Sendable {
    private let visibleWatchItemLimit: Int
    private let warningEventSummaryLimit = 3
    private let warningMessageLimit = 96

    public init(visibleWatchItemLimit: Int = 5) {
        self.visibleWatchItemLimit = visibleWatchItemLimit
    }
```

**Single display mapping pattern** (lines 67-94):
```swift
let sortedItems = sortByAttention(snapshot.trackedItems)
let visibleItems = sortedItems.prefix(visibleWatchItemLimit).map { makeDisplayItem($0, now: now) }
let hiddenCount = max(0, sortedItems.count - visibleItems.count)
let freshnessReason = staleAgeOutReason(for: snapshot, now: now, staleAfterSeconds: staleAfterSeconds)
let resolvedState = stateOverride ?? (freshnessReason == nil ? evaluateState(snapshot) : .stale)
let warningEventSummaries = makeWarningEventSummaries(from: snapshot.warningEventsSection.value ?? [], now: now)
let sectionNotices = makeSectionNotices(from: snapshot.sectionFailures)
let staleReason = failureReason ?? freshnessReason
let lastUpdated = relativeAge(from: snapshot.capturedAt, to: now)

return MenuDisplayModel(
    state: resolvedState,
    contextName: snapshot.contextName,
    healthSentence: healthSentence(for: resolvedState, visibleItems: visibleItems),
    primaryStatusReason: primaryStatusReason(for: resolvedState, snapshot: snapshot, visibleItems: visibleItems, sectionNotices: sectionNotices, staleReason: staleReason),
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
    sectionNotices: sectionNotices
)
```

**Unavailable/stale/error-safe pattern** (lines 130-142, 323-337):
```swift
private func makeSectionNotices(from sectionFailures: [SnapshotSectionFailure]) -> [SectionAvailabilityDisplay] {
    sectionFailures.map { failure in
        SectionAvailabilityDisplay(
            id: failure.section.rawValue,
            title: failure.section.displayName,
            reason: sanitizedSectionReason(failure.reason)
        )
    }
}

private func sanitizedSectionReason(_ value: String) -> String {
    normalizedText(value) ?? "Section unavailable"
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
```

**Warning grouping/cap pattern** (lines 170-209):
```swift
private func makeWarningEventSummaries(from warningEvents: [WarningEventRecord], now: Date) -> [WarningEventDisplay] {
    var groups: [WarningEventGroupKey: WarningEventGroup] = [:]

    for event in warningEvents {
        let key = WarningEventGroupKey(event: event)
        groups[key, default: WarningEventGroup(key: key, reason: event.reason)]
            .add(event, message: shortenedWarningMessage(event.message))
    }

    return groups.values
        .sorted { left, right in
            let leftDate = left.observedAt ?? .distantPast
            let rightDate = right.observedAt ?? .distantPast

            if leftDate != rightDate {
                return leftDate > rightDate
            }
```

**Apply to Phase 09:**
- Keep all display contract shaping here.
- If separate Overview/Event caps are required, add explicit limit fields or derived display arrays here and test them.
- Keep visible watchlist cap at 3-5, default currently 5.
- Do not add `kubectl` reads or SwiftUI concepts to this service.

---

### `KubebarTests/Models/MenuDisplayModelTests.swift` (test, transform)

**Analog:** `KubebarTests/Models/MenuDisplayModelTests.swift`

**Test imports/suite pattern** (lines 1-7):
```swift
import Foundation
import Testing
@testable import KubebarCore

@Suite("Menu display model")
struct MenuDisplayModelTests {
    @Test("healthy snapshots show OK status and compact counters")
```

**Model mapping test pattern** (lines 7-30):
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
    #expect(display.primaryStatusReason == "Cluster looks healthy")
    #expect(display.lastUpdated == "20s ago")
}
```

**Cap/stale/unavailable patterns** (lines 127-145, 200-227, 405-422):
```swift
@Test("first screen caps watchlist and reports overflow")
func firstScreenCapsWatchlistAndReportsOverflow() {
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

    #expect(display.visibleWatchItems.count == 5)
    #expect(display.hiddenWatchItemCount == 2)
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
    #expect(display.visibleWatchItems.first?.title == "api/checkout")
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
    #expect(display.sectionNotices.contains { $0.title == "Warning events" && $0.reason == "invalid event JSON" })
}
```

**Apply to Phase 09:**
- Add tests here for any tab-specific display fields, section-notice caps, Overview one-notice behavior, Nodes/Pods/Events empty/unavailable/stale states.
- Use deterministic dates.
- Test core mapping directly; do not add UI snapshot tests unless the planner also adds a UI test target.

---

### `KubebarTests/Models/MenuTabStateTests.swift` (test, event-driven)

**Analog:** `KubebarTests/Models/MenuRuntimeStateTests.swift`

**State transition test pattern** (lines 1-14, 26-39):
```swift
import Testing
@testable import KubebarCore

@Suite("Menu runtime state")
struct MenuRuntimeStateTests {
    @Test("fresh config starts setup and requests contexts")
    func freshConfigStartsSetupAndRequestsContexts() {
        let state = MenuRuntimeState(config: AppConfig())

        #expect(state.surface == .setup)
        #expect(state.isShowingSetup)
        #expect(state.shouldLoadContexts)
        #expect(state.targetContextToLoad == nil)
    }

    @Test("configured app starts on menu")
    func configuredAppStartsOnMenu() {
        let state = MenuRuntimeState(
            config: AppConfig(
                selectedContext: "prod",
                watchTargets: [.namespace("api")]
            )
        )

        #expect(state.surface == .menu)
        #expect(!state.isShowingSetup)
        #expect(!state.shouldLoadContexts)
        #expect(state.targetContextToLoad == nil)
    }
}
```

**Apply to Phase 09:**
- Add a `MenuTabStateTests.swift` only if tab behavior is extracted into `KubebarCore`.
- If tabs stay as `@State` inside SwiftUI, do not create a core test just to test SwiftUI local state.
- Required behavior to cover if extracted: fixed tab list, Overview default, tab switch has no refresh/read side effects, Settings is not a tab.

---

### `.planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-UAT.md` (manual validation, event-driven)

**Analog:** `.planning/phases/09-codexbar-inspired-tabbed-menu-redesign/09-VALIDATION.md`

**Validation contract pattern** (lines 16-24):
```markdown
## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Swift Testing with `import Testing`, `@Suite`, `@Test`, and `#expect` |
| Config file | `Package.swift` test target `KubebarCoreTests`; `project.yml` Xcode target `KubebarTests` |
| Quick run command | `swift test --filter MenuDisplayModelTests` |
| Full suite command | `./scripts/swift-quality-gate.sh local` |
| Visible app smoke command | `./scripts/compile-and-run.sh` |
```

**Manual-only pattern** (lines 64-72):
```markdown
| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visible tab switching in the menu bar window | REQ-09-01, REQ-09-02 | Prior evidence shows menu-bar extras may not be inspectable through automation. | Run `./scripts/compile-and-run.sh`, open the menu, switch `Overview`, `Nodes`, `Pods`, and `Events`, and record `09-UAT.md` with screenshot path or `pending-human-verification`. |
| Settings opens independently | REQ-09-07 | SwiftUI Settings presentation is app-shell behavior, not covered by current model tests. | Open menu, activate `Settings...`, confirm a separate settings dialog/window appears, and record `09-UAT.md`. |
| Quit exits without config loss | REQ-09-08 | Actual app termination and post-quit config preservation need visible app evidence. | Record config before launching, activate `Quit Kubebar`, relaunch, confirm context/watchlist/cadence remain present, and summarize in `09-UAT.md`. |
```

**Apply to Phase 09:**
- Create UAT rows for OK, Watch, Bad, Stale, tab switching, reopen reset, empty watchlist, Settings, Quit, keyboard navigation, and long names.
- Use `pending-human-verification` when menu bar UI cannot be inspected by automation.

## Shared Patterns

### Product Guardrails

**Source:** `AGENTS.md`
**Apply to:** All app, view, model, service, and test files

```markdown
- Keep the menu bar icon categorical: `OK`, `Watch`, `Bad`, or `Stale`.
- Keep the dropdown watchlist-first.
- Keep first-screen watchlist rows capped at `3-5` items.
- Never let stale data look healthy or current.
- Keep deep troubleshooting out of version 1.
```

Source lines: `AGENTS.md` lines 11-17.

### Display Ownership

**Source:** `AGENTS.md` and `.planning/codebase/ARCHITECTURE.md`
**Apply to:** All SwiftUI views and all `KubebarCore` display changes

```markdown
- UI renders `MenuDisplayModel`; it must not decide cluster health directly.
- `HealthEvaluator` is the single source of truth for severity.
- External reads must go through an injectable boundary.
- App-owned context is the source of truth, not the terminal's current context.
```

Source lines: `AGENTS.md` lines 19-25; `.planning/codebase/ARCHITECTURE.md` lines 7-15 and 74-80.

### Thin SwiftUI Views

**Source:** `.planning/codebase/ARCHITECTURE.md`
**Apply to:** `Kubebar/Views/*.swift`

```markdown
- Use this layer for layout and simple presentation.
- Pass closures for actions and bindings for setup state.
- Do not read files, call `kubectl`, or calculate severity.
```

Source lines: `.planning/codebase/ARCHITECTURE.md` lines 34-40.

### Truncation and Accessibility

**Source:** `StatusSummaryView.swift`, `WatchlistSectionView.swift`, `WarningEventsView.swift`, `TrackedItemDetailView.swift`
**Apply to:** Tab rows, context names, workload names, pod examples, warning locations, node names if added

```swift
Text(item.title)
    .lineLimit(1)
    .truncationMode(.middle)
    .help(Text(item.title))
    .accessibilityLabel(item.title)
```

Source lines: `Kubebar/Views/WatchlistSectionView.swift` lines 45-49.

### Stale Data Visibility

**Source:** `StaleBannerView.swift`, `HealthEvaluator.swift`, `MenuDisplayModelTests.swift`
**Apply to:** Overview, Nodes, Pods, Events, menu bar icon state

```swift
if let banner {
    VStack(alignment: .leading, spacing: 4) {
        Text("Stale")
            .font(.caption.weight(.semibold))

        Text("Last updated \(banner.lastUpdated). \(banner.reason).")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
}
```

Source lines: `Kubebar/Views/StaleBannerView.swift` lines 7-20.

### Settings and Config Persistence

**Source:** `MenuBarViewModel.swift`, `SetupView.swift`, `WatchlistPickerView.swift`, `MenuRuntimeState.swift`
**Apply to:** Settings scene/root, setup/edit mode, save action

```swift
do {
    try configStore.save(config)
    invalidateRefreshState(clearSnapshot: true)
    display = Self.initialDisplay(for: config, now: Date())
    runtimeState.completeSetupSaved()
    publishRuntimeState()
    performRefresh(queueIfBusy: true)
    startRefreshLoopIfConfigured()
} catch {
    runtimeState.markConfigurationSaveFailed("Could not save setup. Try again.")
    publishRuntimeState()
}
```

Source lines: `Kubebar/MenuBarViewModel.swift` lines 140-153.

### Testing

**Source:** `.planning/codebase/TESTING.md` and `MenuDisplayModelTests.swift`
**Apply to:** All model/service changes

```swift
import Foundation
import Testing
@testable import KubebarCore

@Suite("Menu display model")
struct MenuDisplayModelTests {
    @Test("healthy snapshots show OK status and compact counters")
```

Source lines: `KubebarTests/Models/MenuDisplayModelTests.swift` lines 1-7.

Run commands from `.planning/codebase/TESTING.md` lines 17-22:

```bash
./scripts/swift-quality-gate.sh local
swift test
xcodebuild -project Kubebar.xcodeproj -scheme Kubebar -configuration Debug -destination 'platform=macOS' test CODE_SIGNING_ALLOWED=NO
```

## No Analog Found

Files or behaviors with no close local implementation analog:

| File / Behavior | Role | Data Flow | Reason | Fallback |
|-----------------|------|-----------|--------|----------|
| SwiftUI `Settings` scene in `Kubebar/KubebarApp.swift` | app shell | event-driven | No current `Settings`, `openSettings`, or independent settings window exists in app code. | Use Phase 09 research lines 183-185, 348-363, 425-431. |
| `Quit Kubebar` app termination action | app shell/action | event-driven | No current app-level quit button or `NSApplication.shared.terminate` call exists in app code. | Use Phase 09 research lines 183, 371-380, 437-439. |

## Metadata

**Analog search scope:** `Kubebar/`, `KubebarCore/`, `KubebarTests/`, `.planning/codebase/`, `.planning/phases/09-codexbar-inspired-tabbed-menu-redesign/`
**Files scanned:** 48 source/test files plus Phase 09 planning docs
**Pattern extraction date:** 2026-04-22

