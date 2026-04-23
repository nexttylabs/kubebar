import CoreGraphics
import Foundation

public enum FreshnessDisplaySchedule {
    public static func nextUpdateDelaySeconds(
        capturedAt: Date,
        now: Date,
        staleAfterSeconds: Int?
    ) -> Int {
        let elapsedSeconds = max(0, Int(now.timeIntervalSince(capturedAt)))
        let labelDelaySeconds = nextRelativeAgeLabelDelaySeconds(elapsedSeconds: elapsedSeconds)

        guard let staleAfterSeconds else {
            return labelDelaySeconds
        }

        let staleTransitionElapsedSeconds = max(0, staleAfterSeconds) + 1
        guard elapsedSeconds < staleTransitionElapsedSeconds else {
            return labelDelaySeconds
        }

        let staleDelaySeconds = max(1, staleTransitionElapsedSeconds - elapsedSeconds)
        return min(labelDelaySeconds, staleDelaySeconds)
    }

    private static func nextRelativeAgeLabelDelaySeconds(elapsedSeconds: Int) -> Int {
        if elapsedSeconds < 60 {
            return 1
        }

        if elapsedSeconds < 3_600 {
            let nextMinuteBoundary = ((elapsedSeconds / 60) + 1) * 60
            return max(1, nextMinuteBoundary - elapsedSeconds)
        }

        let nextHourBoundary = ((elapsedSeconds / 3_600) + 1) * 3_600
        return max(1, nextHourBoundary - elapsedSeconds)
    }
}

public enum ScreenVisibleHeightUpdate {
    public static func nextHeight(
        current: CGFloat,
        proposed: CGFloat,
        tolerance: CGFloat = 1
    ) -> CGFloat? {
        guard proposed > 0, abs(current - proposed) > tolerance else {
            return nil
        }

        return proposed
    }
}
