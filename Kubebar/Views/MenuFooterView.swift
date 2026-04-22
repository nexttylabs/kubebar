import SwiftUI
import KubebarCore

struct MenuFooterView: View {
    let lastUpdated: String
    let refreshCadence: RefreshCadence
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void
    let onSelectRefreshCadence: (RefreshCadence) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            refreshControls
            primaryActions
            Divider()
            quitAction
        }
    }

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

            Text("Last updated \(lastUpdated)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()
        }
    }

    private var primaryActions: some View {
        HStack {
            Button("Retry now", action: onRefresh)
                .keyboardShortcut("r", modifiers: .command)
                .help(Text(isRefreshing ? "Refresh in progress" : "Refresh now"))
                .disabled(isRefreshing)

            Spacer()

            Button("Settings...", action: onOpenSettings)
                .keyboardShortcut(",", modifiers: .command)
                .help(Text("Open Settings"))
        }
    }

    private var quitAction: some View {
        HStack {
            Spacer()

            Button("Quit Kubebar", action: onQuit)
                .keyboardShortcut("q", modifiers: .command)
                .help(Text("Quit Kubebar"))
        }
    }

    private var refreshCadenceBinding: Binding<RefreshCadence> {
        Binding(
            get: { refreshCadence },
            set: { onSelectRefreshCadence($0) }
        )
    }
}
