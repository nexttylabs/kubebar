import SwiftUI
import KubebarCore

struct WatchlistPickerView: View {
    @Binding var state: WatchlistSelectionState
    let loadingState: WatchTargetLoadingState
    let onRetryTargets: () -> Void

    init(
        state: Binding<WatchlistSelectionState>,
        loadingState: WatchTargetLoadingState = .idle,
        onRetryTargets: @escaping () -> Void = {}
    ) {
        _state = state
        self.loadingState = loadingState
        self.onRetryTargets = onRetryTargets
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
    }

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

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Watchlist")
                .font(.headline)

            Text(state.isEmpty ? state.emptyStateTitle : state.selectionSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if state.isEmpty {
                Text(state.emptyStateMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var namespaceSection: some View {
        SectionCard(
            title: "Namespaces",
            emptyTitle: "No namespaces yet",
            emptyMessage: "Namespaces keep the watchlist compact when you want whole areas of the cluster on the first screen.",
            hasItems: !state.availableNamespaces.isEmpty
        ) {
            ForEach(state.availableNamespaces, id: \.self) { namespace in
                Toggle(isOn: binding(for: .namespace(namespace))) {
                    Text(namespace)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(Text(namespace))
                        .accessibilityLabel(namespace)
                }
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
                DisclosureGroup {
                    ForEach(group.value, id: \.self) { workload in
                        Toggle(isOn: binding(for: workload.target)) {
                            Text(workload.displayTitle)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(Text(workload.displayTitle))
                                .accessibilityLabel(workload.displayTitle)
                        }
                    }
                } label: {
                    Text(group.key)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(Text(group.key))
                        .accessibilityLabel(group.key)
                }
            }
        }
    }

    private var loadingView: some View {
        StateCard {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)

                Text("Loading watch targets...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
            }
        }
    }

    private var emptyTargetsView: some View {
        StateCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No watch targets found")
                    .font(.subheadline.weight(.medium))

                Text("Kubebar could not find namespaces or supported workloads for this context.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Retry", action: onRetryTargets)
            }
        }
    }

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
}

private struct StateCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    let emptyTitle: String
    let emptyMessage: String
    let hasItems: Bool
    let content: Content

    init(
        title: String,
        emptyTitle: String,
        emptyMessage: String,
        hasItems: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.hasItems = hasItems
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Group {
                if hasItems {
                    content
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(emptyTitle)
                            .font(.subheadline.weight(.medium))

                        Text(emptyMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
