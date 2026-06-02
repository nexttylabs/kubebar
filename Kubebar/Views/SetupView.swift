import SwiftUI
import KubebarCore

struct SetupView: View {
    @Binding var state: SetupFlowState
    let primaryActionTitle: String
    let onComplete: () -> Void
    let onSelectContext: (String?) -> Void
    let onRetryTargets: () -> Void
    let onToggleStartAtLogin: (Bool) -> Void
    let onToggleHealthShiftAlerts: (Bool) -> Void
    let onContentHeightChange: (CGFloat) -> Void

    init(
        state: Binding<SetupFlowState>,
        primaryActionTitle: String = "Finish setup",
        onComplete: @escaping () -> Void = {},
        onSelectContext: @escaping (String?) -> Void = { _ in },
        onRetryTargets: @escaping () -> Void = {},
        onToggleStartAtLogin: @escaping (Bool) -> Void = { _ in },
        onToggleHealthShiftAlerts: @escaping (Bool) -> Void = { _ in },
        onContentHeightChange: @escaping (CGFloat) -> Void = { _ in }
    ) {
        _state = state
        self.primaryActionTitle = primaryActionTitle
        self.onComplete = onComplete
        self.onSelectContext = onSelectContext
        self.onRetryTargets = onRetryTargets
        self.onToggleStartAtLogin = onToggleStartAtLogin
        self.onToggleHealthShiftAlerts = onToggleHealthShiftAlerts
        self.onContentHeightChange = onContentHeightChange
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                contextPicker
                watchlistPicker
                refreshCadencePicker
                startAtLoginToggle
                healthShiftAlertsToggle
                footer
            }
            .padding(20)
            .frame(maxWidth: 560, alignment: .leading)
            .background(ContentHeightReader(onChange: onContentHeightChange))
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
                        Text(context)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(Text(context))
                            .accessibilityLabel(context)
                            .tag(Optional(context))
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

    private var refreshCadencePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Refresh cadence")
                .font(.headline)

            Picker("Refresh cadence", selection: $state.refreshCadence) {
                ForEach(RefreshCadence.allCases) { cadence in
                    Text(cadence.label).tag(cadence)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var startAtLoginToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Start at Login", isOn: startAtLoginBinding)
                .help(Text("Open Kubebar automatically after login."))
                .accessibilityLabel(Text("Start at Login"))

            if let message = state.startAtLogin.message, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var healthShiftAlertsToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Health State Shift Alerts", isOn: healthShiftAlertsBinding)
                .help(Text("Notify when cluster health or watched items get worse."))
                .accessibilityLabel(Text("Health State Shift Alerts"))

            if let message = state.healthShiftAlerts.message, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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

            Button(primaryActionTitle, action: onComplete)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
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

    private var startAtLoginBinding: Binding<Bool> {
        Binding(
            get: { state.startAtLogin.isEnabled },
            set: { onToggleStartAtLogin($0) }
        )
    }

    private var healthShiftAlertsBinding: Binding<Bool> {
        Binding(
            get: { state.healthShiftAlerts.isEnabled },
            set: { onToggleHealthShiftAlerts($0) }
        )
    }
}

private struct ContentHeightReader: View {
    let onChange: (CGFloat) -> Void

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: ContentHeightPreferenceKey.self, value: proxy.size.height)
        }
        .onPreferenceChange(ContentHeightPreferenceKey.self, perform: onChange)
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
