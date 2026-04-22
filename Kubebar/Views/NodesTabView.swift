import SwiftUI
import KubebarCore

struct NodesTabView: View {
    let display: MenuDisplayModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StaleBannerView(banner: display.staleBanner)
            NodeDetailsView(display: display.nodeTab)
        }
    }
}
