import Testing
@testable import KubebarCore

@Suite("Refresh cadence")
struct RefreshCadenceTests {
    @Test("supported cadences expose seconds and labels")
    func supportedCadencesExposeSecondsAndLabels() {
        #expect(RefreshCadence.allCases.map(\.seconds) == [30, 60, 120, 300])
        #expect(RefreshCadence.allCases.map(\.label) == ["30 sec", "1 min", "2 min", "5 min"])
    }

    @Test("default cadence is one minute")
    func defaultCadenceIsOneMinute() {
        #expect(RefreshCadence.default == .oneMinute)
        #expect(RefreshCadence.default.seconds == 60)
    }

    @Test("saved seconds resolve to supported cadence")
    func savedSecondsResolveToSupportedCadence() {
        #expect(RefreshCadence.from(seconds: 30) == .thirtySeconds)
        #expect(RefreshCadence.from(seconds: 60) == .oneMinute)
        #expect(RefreshCadence.from(seconds: 120) == .twoMinutes)
        #expect(RefreshCadence.from(seconds: 300) == .fiveMinutes)
    }

    @Test("unknown saved seconds use default")
    func unknownSavedSecondsUseDefault() {
        #expect(RefreshCadence.from(seconds: 999) == .oneMinute)
    }
}
