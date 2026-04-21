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

    @Test("invalidating while in flight rejects the old ticket and queues one refresh")
    func invalidatingWhileInFlightRejectsOldTicketAndQueuesOneRefresh() {
        var gate = RefreshGate()
        let original = AppConfig(selectedContext: "prod", watchTargets: [.namespace("api")])
        let updated = AppConfig(selectedContext: "stage", watchTargets: [.namespace("web")])
        let ticket = gate.begin(config: original)

        #expect(ticket != nil)
        guard let ticket else {
            return
        }

        gate.invalidate()
        gate.requestPendingRefresh()

        #expect(gate.shouldApply(ticket, currentConfig: original) == false)
        #expect(gate.shouldApply(ticket, currentConfig: updated) == false)
        #expect(gate.finishAndConsumePendingRefresh() == true)
        #expect(gate.finishAndConsumePendingRefresh() == false)
    }

    @Test("ticket does not apply after config changes")
    func ticketDoesNotApplyAfterConfigChanges() {
        var gate = RefreshGate()
        let original = AppConfig(selectedContext: "prod", watchTargets: [.namespace("api")])
        let updated = AppConfig(selectedContext: "prod", watchTargets: [.namespace("web")])
        let ticket = gate.begin(config: original)

        #expect(ticket != nil)
        guard let ticket else {
            return
        }

        #expect(gate.shouldApply(ticket, currentConfig: original) == true)
        #expect(gate.shouldApply(ticket, currentConfig: updated) == false)
    }
}
