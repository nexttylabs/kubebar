import SwiftUI
import KubebarCore

struct StaleBannerView: View {
    let banner: StaleBannerDisplay?

    var body: some View {
        if let banner {
            VStack(alignment: .leading, spacing: 4) {
                Text("Stale")
                    .font(.caption.weight(.semibold))

                Text("Last updated \(banner.lastUpdated). \(banner.reason).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
        }
    }
}
