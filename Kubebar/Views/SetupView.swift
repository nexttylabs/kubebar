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
                settingsTabs
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

    private var settingsTabs: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsTabPicker
            selectedSettingsTabContent
        }
    }

    @ViewBuilder
    private var settingsTabPicker: some View {
        if state.settingsTabs.count > 4 {
            settingsTabPickerContent
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            settingsTabPickerContent
                .pickerStyle(.segmented)
        }
    }

    private var settingsTabPickerContent: some View {
        Picker("Settings tab", selection: selectedSettingsTabBinding) {
            ForEach(state.settingsTabs, id: \.self) { tab in
                Text(tab.title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(tab.helpText))
                    .accessibilityLabel(Text(tab.helpText))
                    .tag(tab)
            }
        }
        .labelsHidden()
    }

    @ViewBuilder
    private var selectedSettingsTabContent: some View {
        switch state.selectedSettingsTab {
        case .appSettings:
            appSettingsContent
        case let .context(context):
            contextSettingsContent(for: context)
        }
    }

    private var appSettingsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            refreshCadencePicker
            startAtLoginToggle
            healthShiftAlertsToggle
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func contextSettingsContent(for context: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Context watchlist")
                    .font(.headline)

                Text(context)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(context))
                    .accessibilityLabel(Text(context))
            }

            WatchlistPickerView(
                state: watchlistBinding,
                loadingState: state.targetLoadingState,
                onRetryTargets: onRetryTargets
            )
        }
    }

    private var selectedSettingsTabBinding: Binding<SettingsTabSelection> {
        Binding(
            get: { state.selectedSettingsTab },
            set: { tab in
                switch tab {
                case .appSettings:
                    state.selectAppSettingsTab()
                    state.configurationMessage = nil
                case let .context(context):
                    onSelectContext(context)
                }
            }
        )
    }

    private var footerHelpText: String {
        switch state.selectedSettingsTab {
        case .appSettings:
            if state.contextTabs.isEmpty {
                return "No contexts available."
            }

            if let context = state.selectedContextForCompletedConfig {
                return "Active context: \(context)"
            }

            return "Choose a context tab to finish setup."
        case .context:
            return state.watchlistHelpText
        }
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
                Text(footerHelpText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(primaryActionTitle, action: onComplete)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!state.isConfigured)
        }
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
