import CoreGraphics

public enum MenuLayoutSizing {
    public static let selectedTabReservedHeight: CGFloat = 170

    public static func maximumMenuHeight(
        forScreenVisibleHeight visibleHeight: CGFloat,
        minimumHeight: CGFloat,
        screenEdgeInset: CGFloat
    ) -> CGFloat {
        let safeVisibleHeight = max(visibleHeight, minimumHeight)
        return max(minimumHeight, safeVisibleHeight - screenEdgeInset)
    }

    public static func contentHeight(
        forMenuHeight menuHeight: CGFloat,
        reservedHeight: CGFloat,
        preferredHeight: CGFloat
    ) -> CGFloat {
        min(preferredHeight, max(0, menuHeight - reservedHeight))
    }

    public static func fillerHeight(
        forContentHeight contentHeight: CGFloat,
        minimumHeight: CGFloat
    ) -> CGFloat {
        max(0, minimumHeight - max(0, contentHeight))
    }
}
