import SwiftUI

struct MenuFooterView: View {
    let lastUpdated: String
    let isRefreshing: Bool
    let activeContextName: String?
    let contextSelectorContexts: [String]
    let onRefresh: () -> Void
    let onSelectContext: (String) -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("Last checked \(lastUpdated)")
                .font(.caption)
                .foregroundStyle(.primary.opacity(0.7))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 12)

            footerToolbar
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footerToolbar: some View {
        HStack(spacing: 6) {
            QuickContextSelectorMenu(
                activeContextName: activeContextName,
                contexts: contextSelectorContexts,
                onSelectContext: onSelectContext
            )

            ControlGroup {
                refreshButton
                settingsButton
                quitButton
            }
            .controlSize(.small)
        }
    }

    private var refreshButton: some View {
        Button(action: onRefresh) {
            Label(
                isRefreshing ? "Refresh in progress" : "Refresh now",
                systemImage: "arrow.clockwise"
            )
            .labelStyle(.iconOnly)
        }
        .keyboardShortcut("r", modifiers: .command)
        .help(Text(isRefreshing ? "Refresh in progress" : "Refresh now"))
        .accessibilityLabel(Text(isRefreshing ? "Refresh in progress" : "Refresh now"))
        .disabled(isRefreshing)
    }

    private var settingsButton: some View {
        Button(action: onOpenSettings) {
            Label("Open Settings", systemImage: "gearshape")
                .labelStyle(.iconOnly)
        }
        .keyboardShortcut(",", modifiers: .command)
        .help(Text("Open Settings"))
        .accessibilityLabel(Text("Open Settings"))
    }

    private var quitButton: some View {
        Button(action: onQuit) {
            Label("Quit Kubebar", systemImage: "power")
                .labelStyle(.iconOnly)
        }
        .keyboardShortcut("q", modifiers: .command)
        .help(Text("Quit Kubebar"))
        .accessibilityLabel(Text("Quit Kubebar"))
    }
}

private struct QuickContextSelectorMenu: View {
    let activeContextName: String?
    let contexts: [String]
    let onSelectContext: (String) -> Void

    var body: some View {
        Menu {
            if contexts.isEmpty {
                Text("No contexts available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(contexts, id: \.self) { context in
                    Toggle(isOn: Binding(
                        get: { context == activeContextName },
                        set: { _ in onSelectContext(context) }
                    )) {
                        Text(context)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .help(Text(context))
                    .accessibilityLabel(Text(accessibilityLabel(for: context)))
                }
            }
        } label: {
            Label(accessibilityText, systemImage: "server.rack")
                .labelStyle(.iconOnly)
        }
        .menuStyle(.button)
        .controlSize(.small)
        .help(Text(helpText))
        .accessibilityLabel(Text(accessibilityText))
    }

    private var helpText: String {
        if let activeContextName {
            return "Current context: \(activeContextName)"
        }

        return "No context selected"
    }

    private var accessibilityText: String {
        "Quick Context Selector, \(activeContextName ?? "not configured")"
    }

    private func accessibilityLabel(for context: String) -> String {
        if context == activeContextName {
            return "Current context, \(context)"
        }

        return "Switch to context \(context)"
    }
}
