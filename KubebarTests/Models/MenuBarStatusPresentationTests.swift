import Testing
@testable import KubebarCore

@Suite("Menu bar status presentation")
struct MenuBarStatusPresentationTests {
    @Test("maps health states to distinct symbols and labels")
    func mapsHealthStatesToDistinctSymbolsAndLabels() {
        #expect(MenuBarStatusPresentation(state: .ok).symbolName == "circle")
        #expect(MenuBarStatusPresentation(state: .watch).symbolName == "exclamationmark.circle")
        #expect(MenuBarStatusPresentation(state: .bad).symbolName == "xmark.octagon")
        #expect(MenuBarStatusPresentation(state: .stale).symbolName == "clock")

        #expect(MenuBarStatusPresentation(state: .bad).accessibilityLabel == "Kubebar Bad")
    }
}
