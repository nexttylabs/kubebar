import SwiftUI
import KubebarCore

struct EventsTabView: View {
    let display: MenuDisplayModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StaleBannerView(banner: display.staleBanner)
            WarningEventsView(display: display.eventsTab)
        }
    }
}
