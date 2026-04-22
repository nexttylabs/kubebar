import SwiftUI

struct ConfigurationRequiredView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a cluster context and watchlist in Settings to begin.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Settings...", action: onOpenSettings)
                .keyboardShortcut(",", modifiers: .command)
                .help(Text("Open Settings"))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Choose a cluster context and watchlist in Settings to begin.")
    }
}
