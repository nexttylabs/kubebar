import SwiftUI
import KubebarCore

struct SetupView: View {
    @Binding var state: SetupFlowState
    let primaryActionTitle: String
    let onComplete: () -> Void
    let onSelectAppSettings: () -> Void
    let onSelectAppPage: (SettingsTabSelection) -> Void
    let onSelectContext: (String?) -> Void
    let onRetryTargets: () -> Void
    let onToggleStartAtLogin: (Bool) -> Void
    let onToggleHealthShiftAlerts: (Bool) -> Void
    let onAddKubeconfigPaths: () -> Void
    let onRemoveKubeconfigPath: (Int) -> Void
    let onMoveKubeconfigPathUp: (Int) -> Void
    let onMoveKubeconfigPathDown: (Int) -> Void
    let onUpdateAIProvider: (AIProvider) -> Void
    let onUpdateAIModelID: (String) -> Void
    let onUpdateAIBaseURL: (String) -> Void
    let onUpdateAIAPIKeyDraft: (String) -> Void
    let onTestAIConnection: () -> Void

    init(
        state: Binding<SetupFlowState>,
        primaryActionTitle: String = "Finish setup",
        onComplete: @escaping () -> Void = {},
        onSelectAppSettings: @escaping () -> Void = {},
        onSelectAppPage: @escaping (SettingsTabSelection) -> Void = { _ in },
        onSelectContext: @escaping (String?) -> Void = { _ in },
        onRetryTargets: @escaping () -> Void = {},
        onToggleStartAtLogin: @escaping (Bool) -> Void = { _ in },
        onToggleHealthShiftAlerts: @escaping (Bool) -> Void = { _ in },
        onAddKubeconfigPaths: @escaping () -> Void = {},
        onRemoveKubeconfigPath: @escaping (Int) -> Void = { _ in },
        onMoveKubeconfigPathUp: @escaping (Int) -> Void = { _ in },
        onMoveKubeconfigPathDown: @escaping (Int) -> Void = { _ in },
        onUpdateAIProvider: @escaping (AIProvider) -> Void = { _ in },
        onUpdateAIModelID: @escaping (String) -> Void = { _ in },
        onUpdateAIBaseURL: @escaping (String) -> Void = { _ in },
        onUpdateAIAPIKeyDraft: @escaping (String) -> Void = { _ in },
        onTestAIConnection: @escaping () -> Void = {}
    ) {
        _state = state
        self.primaryActionTitle = primaryActionTitle
        self.onComplete = onComplete
        self.onSelectAppSettings = onSelectAppSettings
        self.onSelectAppPage = onSelectAppPage
        self.onSelectContext = onSelectContext
        self.onRetryTargets = onRetryTargets
        self.onToggleStartAtLogin = onToggleStartAtLogin
        self.onToggleHealthShiftAlerts = onToggleHealthShiftAlerts
        self.onAddKubeconfigPaths = onAddKubeconfigPaths
        self.onRemoveKubeconfigPath = onRemoveKubeconfigPath
        self.onMoveKubeconfigPathUp = onMoveKubeconfigPathUp
        self.onMoveKubeconfigPathDown = onMoveKubeconfigPathDown
        self.onUpdateAIProvider = onUpdateAIProvider
        self.onUpdateAIModelID = onUpdateAIModelID
        self.onUpdateAIBaseURL = onUpdateAIBaseURL
        self.onUpdateAIAPIKeyDraft = onUpdateAIAPIKeyDraft
        self.onTestAIConnection = onTestAIConnection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                settingsSidebar
                Divider()
                settingsDetail
            }
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var settingsSidebar: some View {
        List(selection: selectedSettingsTabIDBinding) {
            Section("App") {
                ForEach(Array(SetupFlowState.appPages.enumerated()), id: \.element.id) { index, page in
                    sidebarRow(
                        title: page.title,
                        icon: page.systemImageName,
                        tabID: page.id,
                        help: page.helpText,
                        warning: false
                    )
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
            }

            if !state.contextTabs.isEmpty {
                Section("Contexts") {
                    ForEach(state.contextTabs, id: \.self) { context in
                        sidebarRow(
                            title: context,
                            icon: "server.rack",
                            tabID: SettingsTabID.context(context),
                            help: context,
                            warning: state.watchlistState(for: context).isNamespaceSelectionEmpty
                        )
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(width: 180, alignment: .leading)
    }

    private func sidebarRow(title: String, icon: String, tabID: SettingsTabID, help: String, warning: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .leading)

            Text(title)
                .lineLimit(1)

            Spacer()

            if warning {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .help(Text("No namespaces selected"))
            }
        }
        .tag(tabID)
        .help(Text(help))
    }

    private var settingsDetail: some View {
        ScrollView {
            settingsTabContent(for: selectedSettingsTab)
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func settingsTabContent(for tab: SettingsTabSelection) -> some View {
        switch tab {
        case .general:
            generalContent
        case .kubernetes:
            kubernetesContent
        case .notifications:
            notificationsContent
        case .aiAssistant:
            aiAssistantContent
        case let .context(context):
            contextSettingsContent(for: context)
        }
    }

    private var generalContent: some View {
        SettingsContentPane {
            SettingsPaneHeader(
                title: "General",
                subtitle: appSettingsSubtitle
            )

            SettingsSection(title: "Refresh") {
                SettingsRow(label: "Refresh cadence") {
                    refreshCadencePicker
                }
            }

            SettingsSection(title: "Launch") {
                startAtLoginToggle
            }
        }
    }

    private var kubernetesContent: some View {
        SettingsContentPane {
            SettingsPaneHeader(
                title: "Kubernetes",
                subtitle: "How Kubebar discovers kubeconfig files for app-owned kubectl reads."
            )

            SettingsSection(title: "Kubeconfig") {
                kubeconfigPathsSection
            }
        }
    }

    private var notificationsContent: some View {
        SettingsContentPane {
            SettingsPaneHeader(
                title: "Notifications",
                subtitle: "Local alerts for meaningful health changes. Alerts never change cluster health."
            )

            SettingsSection(title: "Alerts") {
                healthShiftAlertsToggle
            }
        }
    }

    private var aiAssistantContent: some View {
        SettingsContentPane {
            SettingsPaneHeader(
                title: "AI Assistant",
                subtitle: "Optional manual AI provider configuration for diagnostic help."
            )

            Text("Test Connection sends only a provider ping. Kubernetes data is never sent. API keys are stored in macOS Keychain.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            SettingsSection(title: "Provider configuration") {
                SettingsRow(label: "Provider") {
                    Picker("AI Provider", selection: aiProviderBinding) {
                        Text("OpenAI").tag(AIProvider.openAI)
                        Text("Anthropic").tag(AIProvider.anthropic)
                        Text("Google Gemini").tag(AIProvider.gemini)
                        Text("OpenAI-compatible").tag(AIProvider.openAICompatible)
                    }
                    .labelsHidden()
                    .accessibilityLabel(Text("AI Provider"))
                }

                SettingsRow(label: "Model ID") {
                    TextField("gpt-4o-mini", text: aiModelIDBinding)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(Text("AI Model ID"))
                }

                if state.aiDiagnosticAssistant.config.provider == .openAICompatible {
                    SettingsRow(label: "Base URL") {
                        TextField("https://example.test/v1", text: aiBaseURLBinding)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel(Text("AI Base URL"))
                    }
                }
            }

            SettingsSection(title: "Connection") {
                SettingsRow(label: "API Key") {
                    SecureField("Leave blank to keep saved key", text: aiAPIKeyDraftBinding)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(Text("AI API Key"))
                }

                SettingsRow(label: "Status") {
                    VStack(alignment: .leading, spacing: 6) {
                        Button("Test Connection", action: onTestAIConnection)
                            .buttonStyle(.bordered)
                            .accessibilityLabel(Text("Test AI Connection"))

                        if let message = state.aiDiagnosticAssistant.testConnectionMessage, !message.isEmpty {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
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
                case .general, .kubernetes, .notifications, .aiAssistant:
                    state.selectAppPage(tab)
                    onSelectAppPage(tab)
                case let .context(context):
                    onSelectContext(context)
                }
            }
        )
    }

    private var footerHelpText: String {
        switch selectedSettingsTab {
        case .general, .kubernetes, .notifications, .aiAssistant:
            if let configurationMessage = state.configurationMessage, !configurationMessage.isEmpty {
                return configurationMessage
            }

            return "App settings apply across all contexts."
        case .context:
            return state.configurationMessage ?? ""
        }
    }

    private var appSettingsSubtitle: String {
        "Configure app-wide behavior such as refresh cadence and startup."
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
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
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

    private var aiProviderBinding: Binding<AIProvider> {
        Binding(
            get: { state.aiDiagnosticAssistant.config.provider },
            set: { onUpdateAIProvider($0) }
        )
    }

    private var aiModelIDBinding: Binding<String> {
        Binding(
            get: { state.aiDiagnosticAssistant.config.modelID },
            set: { onUpdateAIModelID($0) }
        )
    }

    private var aiBaseURLBinding: Binding<String> {
        Binding(
            get: { state.aiDiagnosticAssistant.config.baseURL ?? "" },
            set: { onUpdateAIBaseURL($0) }
        )
    }

    private var aiAPIKeyDraftBinding: Binding<String> {
        Binding(
            get: { state.aiDiagnosticAssistant.apiKeyDraft },
            set: { onUpdateAIAPIKeyDraft($0) }
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
        .frame(maxWidth: .infinity, alignment: .topLeading)
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
                .frame(maxWidth: 360, alignment: .leading)
        }
    }
}
