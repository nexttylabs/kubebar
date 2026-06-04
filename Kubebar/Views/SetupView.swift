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
    let onAddKubeconfigPaths: () -> Void
    let onRemoveKubeconfigPath: (Int) -> Void
    let onMoveKubeconfigPathUp: (Int) -> Void
    let onMoveKubeconfigPathDown: (Int) -> Void

    init(
        state: Binding<SetupFlowState>,
        primaryActionTitle: String = "Finish setup",
        onComplete: @escaping () -> Void = {},
        onSelectAppSettings: @escaping () -> Void = {},
        onSelectContext: @escaping (String?) -> Void = { _ in },
        onRetryTargets: @escaping () -> Void = {},
        onToggleStartAtLogin: @escaping (Bool) -> Void = { _ in },
        onToggleHealthShiftAlerts: @escaping (Bool) -> Void = { _ in },
        onAddKubeconfigPaths: @escaping () -> Void = {},
        onRemoveKubeconfigPath: @escaping (Int) -> Void = { _ in },
        onMoveKubeconfigPathUp: @escaping (Int) -> Void = { _ in },
        onMoveKubeconfigPathDown: @escaping (Int) -> Void = { _ in }
    ) {
        _state = state
        self.primaryActionTitle = primaryActionTitle
        self.onComplete = onComplete
        self.onSelectAppSettings = onSelectAppSettings
        self.onSelectContext = onSelectContext
        self.onRetryTargets = onRetryTargets
        self.onToggleStartAtLogin = onToggleStartAtLogin
        self.onToggleHealthShiftAlerts = onToggleHealthShiftAlerts
        self.onAddKubeconfigPaths = onAddKubeconfigPaths
        self.onRemoveKubeconfigPath = onRemoveKubeconfigPath
        self.onMoveKubeconfigPathUp = onMoveKubeconfigPathUp
        self.onMoveKubeconfigPathDown = onMoveKubeconfigPathDown
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsTabs
            footer
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        SettingsContentPane {
            SettingsPaneHeader(
                title: "App Settings",
                subtitle: appSettingsSubtitle
            )

            SettingsSection(title: "General") {
                SettingsRow(label: "Refresh cadence") {
                    refreshCadencePicker
                }
            }

            SettingsSection(title: "Kubeconfig") {
                kubeconfigPathsSection
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
        SettingsContentPane {
            SettingsPaneHeader(
                title: "\(context) Watchlist",
                subtitle: state.watchlist.isNamespaceSelectionEmpty
                    ? state.watchlist.emptyStateTitle
                    : state.watchlist.namespaceSelectionSummary
            )
            .help(Text(context))

            WatchlistPickerView(
                state: watchlistBinding,
                loadingState: state.targetLoadingState,
                onRetryTargets: onRetryTargets
            )
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
            if let configurationMessage = state.configurationMessage, !configurationMessage.isEmpty {
                return configurationMessage
            }

            if state.contextTabs.isEmpty {
                return "No contexts available."
            }

            if let context = state.selectedContextForCompletedConfig {
                return "Active context: \(context)"
            }

            return "Choose a context tab to finish setup."
        case .context:
            return state.configurationMessage ?? ""
        }
    }

    private var appSettingsSubtitle: String {
        if let context = state.selectedContextForCompletedConfig {
            return "Active context: \(context)"
        }

        if state.contextTabs.isEmpty {
            return "No local contexts available."
        }

        return "Choose a context tab to finish setup."
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

    private var kubeconfigPathsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsRow(label: "Source") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(state.usesAutomaticKubeconfigDetection ? "Automatic detection" : "Explicit path list")
                    Text(kubeconfigPathsHelpText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            SettingsRow(label: "Files") {
                VStack(alignment: .leading, spacing: 8) {
                    if state.kubeconfigPaths.isEmpty {
                        Text("No explicit kubeconfig files. Kubebar will use automatic detection.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(state.kubeconfigPaths.enumerated()), id: \.offset) { entry in
                                kubeconfigPathRow(path: entry.element, index: entry.offset)
                            }
                        }
                    }

                    Button("Add Files", action: onAddKubeconfigPaths)
                        .buttonStyle(.bordered)
                        .accessibilityLabel(Text("Add kubeconfig files"))
                }
            }
        }
    }

    private func kubeconfigPathRow(path: String, index: Int) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(path)
                .font(.callout)
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Button {
                    onMoveKubeconfigPathUp(index)
                } label: {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(.borderless)
                .disabled(index == 0)
                .help(Text("Move up"))
                .accessibilityLabel(Text("Move kubeconfig path up"))

                Button {
                    onMoveKubeconfigPathDown(index)
                } label: {
                    Image(systemName: "arrow.down")
                }
                .buttonStyle(.borderless)
                .disabled(index == state.kubeconfigPaths.count - 1)
                .help(Text("Move down"))
                .accessibilityLabel(Text("Move kubeconfig path down"))

                Button(role: .destructive) {
                    onRemoveKubeconfigPath(index)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help(Text("Remove"))
                .accessibilityLabel(Text("Remove kubeconfig path"))
            }
        }
        .padding(.vertical, 4)
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
            if !footerHelpText.isEmpty {
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

    private var kubeconfigPathsHelpText: String {
        state.usesAutomaticKubeconfigDetection
            ? "Use inherited KUBECONFIG first, then fall back to login shell lookup."
            : "Kubebar joins these files with ':' and lets kubectl merge them."
    }
}

private struct SettingsContentPane<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct SettingsPaneHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.middle)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
