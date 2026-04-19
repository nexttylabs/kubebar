import SwiftUI
import KubebarCore

struct WatchlistPickerView: View {
    @Binding var state: WatchlistSelectionState
    let onRequestAddNamespace: () -> Void
    let onRequestAddWorkload: () -> Void

    init(
        state: Binding<WatchlistSelectionState>,
        onRequestAddNamespace: @escaping () -> Void = {},
        onRequestAddWorkload: @escaping () -> Void = {}
    ) {
        _state = state
        self.onRequestAddNamespace = onRequestAddNamespace
        self.onRequestAddWorkload = onRequestAddWorkload
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            namespaceSection
            workloadSection
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
            actionTitle: "Add namespace",
            hasItems: !state.availableNamespaces.isEmpty,
            action: onRequestAddNamespace
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
            actionTitle: "Add workload",
            hasItems: !state.availableWorkloads.isEmpty,
            action: onRequestAddWorkload
        ) {
            ForEach(state.availableWorkloads, id: \.self) { workload in
                Toggle(
                    workload.displayTitle,
                    isOn: binding(for: workload)
                )
            }
        }
    }

    private func binding(for target: WatchTarget) -> Binding<Bool> {
        Binding(
            get: { state.isSelected(target) },
            set: { state.setSelected(target, to: $0) }
        )
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    let emptyTitle: String
    let emptyMessage: String
    let actionTitle: String
    let hasItems: Bool
    let action: () -> Void
    let content: Content

    init(
        title: String,
        emptyTitle: String,
        emptyMessage: String,
        actionTitle: String,
        hasItems: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.actionTitle = actionTitle
        self.hasItems = hasItems
        self.action = action
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

                        Button(actionTitle, action: action)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
