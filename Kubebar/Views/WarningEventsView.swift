import SwiftUI

struct WarningEventsView: View {
    let count: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Warning events")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(count == "0" ? "No current warning events" : "\(count) warning events need review")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
