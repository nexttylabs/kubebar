import SwiftUI
import KubebarCore

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
                footer
            }
            .padding(20)
            .frame(maxWidth: 560, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(state.title)
                .font(.largeTitle.weight(.semibold))

            Text(state.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

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
        }
    }

    private var watchlistPicker: some View {
        WatchlistPickerView(
            state: watchlistBinding,
            loadingState: state.targetLoadingState,
            onRetryTargets: onRetryTargets
        )
    }

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
}
