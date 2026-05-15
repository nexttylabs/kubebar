import SwiftUI
import KubebarCore

struct NodesTabView: View {
    let display: MenuDisplayModel
    let k9sHandoffState: K9sHandoffLaunchState
    let onOpenK9sHandoff: (OverviewK9sHandoff) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StaleBannerView(banner: display.staleBanner)
            NodeDetailsView(
                display: display.nodeTab,
                k9sHandoffState: k9sHandoffState,
                onOpenK9sHandoff: onOpenK9sHandoff
            )
        }
    }
}
