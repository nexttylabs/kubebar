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
        HStack(spacing: 10) {
            Text("Last checked \(lastUpdated)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 12)

            footerToolbar
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footerToolbar: some View {
        HStack(spacing: 6) {
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .keyboardShortcut("r", modifiers: .command)
            .help(Text(isRefreshing ? "Refresh in progress" : "Refresh now"))
            .accessibilityLabel(Text(isRefreshing ? "Refresh in progress" : "Refresh now"))
            .disabled(isRefreshing)

            Menu {
                Picker("Refresh cadence", selection: refreshCadenceBinding) {
                    ForEach(RefreshCadence.allCases) { cadence in
                        Text(cadence.label).tag(cadence)
                    }
                }
            } label: {
                Label(refreshCadence.label, systemImage: "timer")
            }
            .labelStyle(.iconOnly)
            .menuStyle(.borderlessButton)
            .controlSize(.small)
            .help(Text("Refresh every \(refreshCadence.label)"))
            .accessibilityLabel(Text("Refresh every \(refreshCadence.label)"))

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .keyboardShortcut(",", modifiers: .command)
            .help(Text("Open Settings"))
            .accessibilityLabel(Text("Open Settings"))

            Button(action: onQuit) {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .keyboardShortcut("q", modifiers: .command)
            .help(Text("Quit Kubebar"))
            .accessibilityLabel(Text("Quit Kubebar"))
        }
    }

    private var refreshCadenceBinding: Binding<RefreshCadence> {
        Binding(
            get: { refreshCadence },
            set: { onSelectRefreshCadence($0) }
        )
    }
}
