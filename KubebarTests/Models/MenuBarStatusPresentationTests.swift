import Testing
@testable import KubebarCore

@Suite("Menu bar status presentation")
struct MenuBarStatusPresentationTests {
    @Test("maps health states to distinct symbols and labels")
    func mapsHealthStatesToDistinctSymbolsAndLabels() {
        #expect(MenuBarStatusPresentation(state: .ok).icon == .system("checkmark.circle"))
        #expect(MenuBarStatusPresentation(state: .watch).icon == .system("exclamationmark.triangle"))
        #expect(MenuBarStatusPresentation(state: .bad).icon == .system("xmark.octagon"))
        #expect(MenuBarStatusPresentation(state: .stale).icon == .system("clock.badge.exclamationmark"))

        #expect(MenuBarStatusPresentation(state: .ok).symbolName == "checkmark.circle")
        #expect(MenuBarStatusPresentation(state: .watch).symbolName == "exclamationmark.triangle")
        #expect(MenuBarStatusPresentation(state: .bad).symbolName == "xmark.octagon")
        #expect(MenuBarStatusPresentation(state: .stale).symbolName == "clock.badge.exclamationmark")

        #expect(MenuBarStatusPresentation(state: .ok).accessibilityLabel == "Kubebar OK")
        #expect(MenuBarStatusPresentation(state: .watch).accessibilityLabel == "Kubebar Watch")
        #expect(MenuBarStatusPresentation(state: .bad).accessibilityLabel == "Kubebar Bad")
        #expect(MenuBarStatusPresentation(state: .stale).accessibilityLabel == "Kubebar Stale")
    }
}
