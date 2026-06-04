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
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
            } else {
                emptyTargetsView
            }
        }
    }

    private var namespaceSection: some View {
        SectionCard(
            title: "Namespaces",
            emptyTitle: "No namespaces yet",
            emptyMessage: "Choose a cluster context or retry loading namespaces.",
            hasItems: !state.availableNamespaces.isEmpty
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(state.availableNamespaces, id: \.self) { namespace in
                        Toggle(isOn: binding(for: .namespace(namespace))) {
                            Text(namespace)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(Text(namespace))
                                .accessibilityLabel(namespace)
                        }
                        .toggleStyle(.checkbox)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var loadingView: some View {
        StateCard {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)

                Text("Loading namespaces...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func failureView(reason: String) -> some View {
        StateCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Could not load namespaces")
                    .font(.subheadline.weight(.medium))

                Text(reason.isEmpty ? "Try loading namespaces again." : reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Retry", action: onRetryTargets)
                    .keyboardShortcut("r", modifiers: .command)
                    .help(Text("Retry loading namespaces"))
            }
        }
    }

    private var emptyTargetsView: some View {
        StateCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No namespaces found")
                    .font(.subheadline.weight(.medium))

                Text("Kubebar could not find namespaces for this context.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Retry", action: onRetryTargets)
                    .keyboardShortcut("r", modifiers: .command)
                    .help(Text("Retry loading namespaces"))
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

private struct StateCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GroupBox {
            content
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
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

            GroupBox {
                if hasItems {
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
