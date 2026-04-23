import Foundation
import Testing
@testable import KubebarCore

@Suite("Freshness display schedule")
struct FreshnessDisplayScheduleTests {
    @Test("current snapshot schedules next second update")
    func currentSnapshotSchedulesNextSecondUpdate() {
        let capturedAt = Date(timeIntervalSince1970: 100)
        let now = Date(timeIntervalSince1970: 100)

        let delay = FreshnessDisplaySchedule.nextUpdateDelaySeconds(
            capturedAt: capturedAt,
            now: now,
            staleAfterSeconds: 120
        )

        #expect(delay == 1)
    }

    @Test("seconds boundary reaches first minute label")
    func secondsBoundaryReachesFirstMinuteLabel() {
        let capturedAt = Date(timeIntervalSince1970: 100)
        let now = Date(timeIntervalSince1970: 159)

        let delay = FreshnessDisplaySchedule.nextUpdateDelaySeconds(
            capturedAt: capturedAt,
            now: now,
            staleAfterSeconds: 120
        )

        #expect(delay == 1)
    }

    @Test("minute label waits for next minute boundary")
    func minuteLabelWaitsForNextMinuteBoundary() {
        let capturedAt = Date(timeIntervalSince1970: 100)
        let now = Date(timeIntervalSince1970: 160)

        let delay = FreshnessDisplaySchedule.nextUpdateDelaySeconds(
            capturedAt: capturedAt,
            now: now,
            staleAfterSeconds: 300
        )

        #expect(delay == 60)
    }

    @Test("minute boundary yields to stale transition when sooner")
    func minuteBoundaryYieldsToStaleTransitionWhenSooner() {
        let capturedAt = Date(timeIntervalSince1970: 100)
        let now = Date(timeIntervalSince1970: 220)

        let delay = FreshnessDisplaySchedule.nextUpdateDelaySeconds(
            capturedAt: capturedAt,
            now: now,
            staleAfterSeconds: 120
        )

        #expect(delay == 1)
    }

    @Test("hour label waits for next hour boundary")
    func hourLabelWaitsForNextHourBoundary() {
        let capturedAt = Date(timeIntervalSince1970: 100)
        let now = Date(timeIntervalSince1970: 3_700)

        let delay = FreshnessDisplaySchedule.nextUpdateDelaySeconds(
            capturedAt: capturedAt,
            now: now,
            staleAfterSeconds: nil
        )

        #expect(delay == 3_600)
    }
}
