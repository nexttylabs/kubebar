import SwiftUI
import KubebarCore

struct SetupView: View {
    @Binding var state: SetupFlowState
    let primaryActionTitle: String
    let onComplete: () -> Void
    let onSelectAppSettings: () -> Void
    let onSelectContext: (String?) -> Void
    let onRetryTargets: () -> Void
    let onToggleStartAtLogin: (Bool) -> Void
    let onToggleHealthShiftAlerts: (Bool) -> Void

    init(
        state: Binding<SetupFlowState>,
        primaryActionTitle: String = "Finish setup",
        onComplete: @escaping () -> Void = {},
        onSelectAppSettings: @escaping () -> Void = {},
        onSelectContext: @escaping (String?) -> Void = { _ in },
        onRetryTargets: @escaping () -> Void = {},
        onToggleStartAtLogin: @escaping (Bool) -> Void = { _ in },
        onToggleHealthShiftAlerts: @escaping (Bool) -> Void = { _ in }
    ) {
        _state = state
        self.primaryActionTitle = primaryActionTitle
        self.onComplete = onComplete
        self.onSelectAppSettings = onSelectAppSettings
        self.onSelectContext = onSelectContext
        self.onRetryTargets = onRetryTargets
        self.onToggleStartAtLogin = onToggleStartAtLogin
        self.onToggleHealthShiftAlerts = onToggleHealthShiftAlerts
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            settingsTabs
            footer
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(state.title)
                .font(.title2.weight(.semibold))

            Text(state.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var settingsTabs: some View {
        TabView(selection: selectedSettingsTabIDBinding) {
            ForEach(state.settingsTabs, id: \.id) { tab in
                settingsTabContent(for: tab)
                    .padding(.top, 12)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImageName)
                    }
                    .tag(tab.id)
                    .help(Text(tab.helpText))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func settingsTabContent(for tab: SettingsTabSelection) -> some View {
        switch tab {
        case .appSettings:
            appSettingsContent
        case let .context(context):
            contextSettingsContent(for: context)
        }
    }

    private var appSettingsContent: some View {
        SettingsPanel {
            SettingsSection(title: "General") {
                SettingsRow(label: "Refresh cadence") {
                    refreshCadencePicker
                }
            }

            SettingsSection(title: "Launch") {
                startAtLoginToggle
            }

            SettingsSection(title: "Alerts") {
                healthShiftAlertsToggle
            }
        }
    }

    private func contextSettingsContent(for context: String) -> some View {
        SettingsPanel {
            SettingsSection(title: "Context") {
                Text(context)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(context))
                    .accessibilityLabel(Text(context))
            }

            SettingsSection(title: "Watchlist") {
                WatchlistPickerView(
                    state: watchlistBinding,
                    loadingState: state.targetLoadingState,
                    onRetryTargets: onRetryTargets
                )
            }
        }
    }

    private var selectedSettingsTab: SettingsTabSelection {
        state.settingsTab(for: state.selectedSettingsTabID) ?? .appSettings
    }

    private var selectedSettingsTabIDBinding: Binding<SettingsTabID> {
        Binding(
            get: { state.selectedSettingsTabID },
            set: { tabID in
                guard let tab = state.settingsTab(for: tabID) else {
                    return
                }

                switch tab {
                case .appSettings:
                    state.selectAppSettingsTab()
                    state.configurationMessage = nil
                    onSelectAppSettings()
                case let .context(context):
                    onSelectContext(context)
                }
            }
        )
    }

    private var footerHelpText: String {
        switch selectedSettingsTab {
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
        Picker("Refresh cadence", selection: $state.refreshCadence) {
            ForEach(RefreshCadence.allCases) { cadence in
                Text(cadence.label).tag(cadence)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var startAtLoginToggle: some View {
        VStack(alignment: .leading, spacing: 6) {
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
        VStack(alignment: .leading, spacing: 6) {
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
        .padding(.top, 2)
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

private struct SettingsPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SettingsRow<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)

            content
                .frame(maxWidth: 280, alignment: .leading)
        }
    }
}
