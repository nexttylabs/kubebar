import Foundation
import Testing
@testable import KubebarCore

@Suite("Watch target")
struct WatchTargetTests {
    @Test("workload kinds expose kubectl resources in setup order")
    func workloadKindsExposeKubectlResourcesInSetupOrder() {
        #expect(WorkloadKind.allCases.map(\.kubectlResource) == [
            "deployments",
            "statefulsets",
            "daemonsets",
            "cronjobs"
        ])
    }

    @Test("workload display title stays compact")
    func workloadDisplayTitleStaysCompact() {
        let target = WatchTarget.workload(namespace: "api", name: "checkout", kind: .deployment)

        #expect(target.displayTitle == "api/checkout")
    }

    @Test("old workload config decodes as deployment")
    func oldWorkloadConfigDecodesAsDeployment() throws {
        let json = """
        {"workload":{"namespace":"api","name":"checkout"}}
        """

        let target = try JSONDecoder().decode(WatchTarget.self, from: Data(json.utf8))

        #expect(target == .workload(namespace: "api", name: "checkout", kind: .deployment))
    }
}
