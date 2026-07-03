import Foundation
import Testing
@testable import KubebarCore

@Suite("App config")
struct AppConfigTests {
    @Test("selecting context preserves watchlists and global settings")
    func selectingContextPreservesWatchlistsAndGlobalSettings() {
        let config = AppConfig(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": [.namespace("api")],
                "stage": [.namespace("web")]
            ],
            refreshIntervalSeconds: 120,
            healthShiftAlertsEnabled: true,
            kubeconfigPaths: [
                "/Users/derek/.kube/config",
                "/Users/derek/.kube/prod.yaml"
            ]
        )

        let updated = config.selectingContext("stage")

        #expect(updated.selectedContext == "stage")
        #expect(updated.watchlistsByContext == config.watchlistsByContext)
        #expect(updated.refreshIntervalSeconds == 120)
        #expect(updated.healthShiftAlertsEnabled)
        #expect(updated.kubeconfigPaths == [
            "/Users/derek/.kube/config",
            "/Users/derek/.kube/prod.yaml"
        ])
        #expect(updated.watchTargets == [.namespace("web")])
        #expect(!updated.needsSetup)
    }

    @Test("kubeconfig paths default empty")
    func kubeconfigPathsDefaultEmpty() {
        let config = AppConfig()

        #expect(config.kubeconfigPaths.isEmpty)
    }

    @Test("selecting context without watchlist marks config incomplete")
    func selectingContextWithoutWatchlistMarksConfigIncomplete() {
        let config = AppConfig(
            selectedContext: "prod",
            watchlistsByContext: [
                "prod": [.namespace("api")]
            ]
        )

        let updated = config.selectingContext("stage")

        #expect(updated.selectedContext == "stage")
        #expect(updated.watchTargets.isEmpty)
        #expect(updated.needsSetup)
    }

    @Test("ai diagnostic assistant config defaults to unconfigured")
    func aiDiagnosticAssistantConfigDefaultsToUnconfigured() {
        let config = AppConfig()

        #expect(config.aiDiagnosticAssistant == AIDiagnosticAssistantConfig())
        #expect(config.aiDiagnosticAssistant.modelID.isEmpty)
        #expect(config.aiDiagnosticAssistant.podPromptInstructions == nil)
        #expect(config.aiDiagnosticAssistant.eventPromptInstructions == nil)
        #expect(config.aiDiagnosticAssistant.effectivePodPromptInstructions == AIDiagnosticAssistantConfig.defaultPodPromptInstructions)
        #expect(config.aiDiagnosticAssistant.effectiveEventPromptInstructions == AIDiagnosticAssistantConfig.defaultEventPromptInstructions)
    }

    @Test("existing config without prompts decodes defaults")
    func existingConfigWithoutPromptsDecodesDefaults() throws {
        let json = """
        {
          "selectedContext": "prod",
          "watchTargets": [{ "namespace": { "_0": "api" } }],
          "aiDiagnosticAssistant": {
            "provider": "openAI",
            "modelID": "gpt-4o-mini"
          }
        }
        """

        let config = try JSONDecoder().decode(AppConfig.self, from: Data(json.utf8))

        #expect(config.aiDiagnosticAssistant.podPromptInstructions == nil)
        #expect(config.aiDiagnosticAssistant.eventPromptInstructions == nil)
        #expect(config.aiDiagnosticAssistant.effectivePodPromptInstructions == AIDiagnosticAssistantConfig.defaultPodPromptInstructions)
        #expect(config.aiDiagnosticAssistant.effectiveEventPromptInstructions == AIDiagnosticAssistantConfig.defaultEventPromptInstructions)
    }

    @Test("custom prompt overrides round trip without api key")
    func customPromptOverridesRoundTripWithoutAPIKey() throws {
        let config = AppConfig(
            selectedContext: "prod",
            watchTargets: [.namespace("api")],
            aiDiagnosticAssistant: AIDiagnosticAssistantConfig(
                provider: .openAI,
                modelID: "gpt-4o-mini",
                podPromptInstructions: "Custom Pod instructions",
                eventPromptInstructions: "Custom Event instructions"
            )
        )

        let data = try JSONEncoder().encode(config)
        let json = String(data: data, encoding: .utf8) ?? ""
        let decoded = try JSONDecoder().decode(AppConfig.self, from: data)

        #expect(decoded.aiDiagnosticAssistant.podPromptInstructions == "Custom Pod instructions")
        #expect(decoded.aiDiagnosticAssistant.eventPromptInstructions == "Custom Event instructions")
        #expect(json.contains("Custom Pod instructions"))
        #expect(json.contains("Custom Event instructions"))
        #expect(!json.contains("apiKey"))
        #expect(!json.contains("sk-test-secret"))
    }

    @Test("selecting context preserves ai diagnostic assistant config")
    func selectingContextPreservesAIDiagnosticAssistantConfig() {
        let config = AppConfig(
            selectedContext: "prod",
            watchlistsByContext: ["prod": [.namespace("api")]],
            aiDiagnosticAssistant: AIDiagnosticAssistantConfig(
                provider: .anthropic,
                modelID: "claude-3",
                baseURL: nil
            )
        )

        let updated = config.selectingContext("stage")

        #expect(updated.aiDiagnosticAssistant == config.aiDiagnosticAssistant)
    }

    @Test("encoded app config never contains an api key")
    func encodedAppConfigNeverContainsApiKey() throws {
        let config = AppConfig(
            selectedContext: "prod",
            watchTargets: [.namespace("api")],
            aiDiagnosticAssistant: AIDiagnosticAssistantConfig(
                provider: .openAICompatible,
                modelID: "gpt-4o-mini",
                baseURL: "https://example.test/v1",
                podPromptInstructions: "Secret-free custom instructions"
            )
        )

        let data = try JSONEncoder().encode(config)
        let json = String(data: data, encoding: .utf8) ?? ""

        #expect(!json.contains("apiKey"))
        #expect(!json.contains("sk-test-secret"))
    }
}
