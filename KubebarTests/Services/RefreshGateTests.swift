import Testing
@testable import KubebarCore

@Suite("Refresh gate")
struct RefreshGateTests {
    @Test("two immediate begins start only one refresh")
    func twoImmediateBeginsStartOnlyOneRefresh() {
        var gate = RefreshGate()

        #expect(gate.begin() == true)
        #expect(gate.begin() == false)
    }

    @Test("finish allows the next refresh")
    func finishAllowsTheNextRefresh() {
        var gate = RefreshGate()

        #expect(gate.begin() == true)
        gate.finish()

        #expect(gate.begin() == true)
    }
}
