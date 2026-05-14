import SwiftUI

struct InlineProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.tertiary)

                RoundedRectangle(cornerRadius: 2)
                    .fill(fillColor)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1.0))
            }
        }
        .frame(height: 4)
    }

    private var fillColor: Color {
        .accentColor
    }
}
