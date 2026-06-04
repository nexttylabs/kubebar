import Testing
@testable import KubebarCore

@Suite("Menu layout sizing")
struct MenuLayoutSizingTests {
    @Test("normal visible screen uses safe maximum menu height")
    func normalVisibleScreenUsesSafeMaximumMenuHeight() {
        let height = MenuLayoutSizing.maximumMenuHeight(
            forScreenVisibleHeight: 900,
            minimumHeight: 220,
            screenEdgeInset: 48
        )

        #expect(height == 852)
    }

    @Test("short visible screen stays within safe visible height")
    func shortVisibleScreenStaysWithinSafeVisibleHeight() {
        let maximumHeight = MenuLayoutSizing.maximumMenuHeight(
            forScreenVisibleHeight: 500,
            minimumHeight: 220,
            screenEdgeInset: 48
        )
        #expect(maximumHeight == 452)
    }

    @Test("tiny visible screen preserves minimum menu height")
    func tinyVisibleScreenPreservesMinimumMenuHeight() {
        let height = MenuLayoutSizing.maximumMenuHeight(
            forScreenVisibleHeight: 120,
            minimumHeight: 220,
            screenEdgeInset: 48
        )

        #expect(height == 220)
    }

    @Test("content height uses remaining menu space without exceeding preferred height")
    func contentHeightUsesRemainingMenuSpaceWithoutExceedingPreferredHeight() {
        #expect(
            MenuLayoutSizing.contentHeight(
                forMenuHeight: 560,
                reservedHeight: MenuLayoutSizing.selectedTabReservedHeight,
                preferredHeight: 560
            ) == 390
        )
        #expect(
            MenuLayoutSizing.contentHeight(
                forMenuHeight: 820,
                reservedHeight: MenuLayoutSizing.selectedTabReservedHeight,
                preferredHeight: 560
            ) == 560
        )
    }

    @Test("content height uses the no top context selector budget")
    func contentHeightUsesTheNoTopContextSelectorBudget() {
        let menuHeight = MenuLayoutSizing.maximumMenuHeight(
            forScreenVisibleHeight: 500,
            minimumHeight: 220,
            screenEdgeInset: 48
        )
        let contentHeight = MenuLayoutSizing.contentHeight(
            forMenuHeight: menuHeight,
            reservedHeight: MenuLayoutSizing.selectedTabReservedHeight,
            preferredHeight: 560
        )

        #expect(contentHeight == 282)
        #expect(contentHeight + MenuLayoutSizing.selectedTabReservedHeight <= menuHeight)
    }

    @Test("short content filler only fills missing height")
    func shortContentFillerOnlyFillsMissingHeight() {
        #expect(
            MenuLayoutSizing.fillerHeight(
                forContentHeight: 120,
                minimumHeight: 280
            ) == 160
        )
        #expect(
            MenuLayoutSizing.fillerHeight(
                forContentHeight: 320,
                minimumHeight: 280
            ) == 0
        )
        #expect(
            MenuLayoutSizing.fillerHeight(
                forContentHeight: -20,
                minimumHeight: 280
            ) == 280
        )
    }
}
