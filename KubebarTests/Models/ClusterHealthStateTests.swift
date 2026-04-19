import Testing
@testable import KubebarCore

@Suite("Cluster health state")
struct ClusterHealthStateTests {
    @Test("uses fixed user-facing labels")
    func usesFixedUserFacingLabels() {
        #expect(ClusterHealthState.ok.label == "OK")
        #expect(ClusterHealthState.watch.label == "Watch")
        #expect(ClusterHealthState.bad.label == "Bad")
        #expect(ClusterHealthState.stale.label == "Stale")
    }
}
