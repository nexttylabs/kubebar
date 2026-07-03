import Foundation
import Testing
@testable import KubebarCore

@Suite("AI Event diagnostic requester")
struct AIEventDiagnosticRequesterTests {
    @Test("missing model ID returns safe local failure")
    func missingModelIDReturnsSafeLocalFailure() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let requester = AIEventDiagnosticRequester(credentialStore: store, httpClient: FakeHTTPClient())

        let result = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: ""),
            provider: .openAI
        )

        #expect(result == .failed(AIProviderConnectionTester.missingModelIDMessage))
    }

    @Test("missing API key returns safe local failure")
    func missingAPIKeyReturnsSafeLocalFailure() async {
        let requester = AIEventDiagnosticRequester(
            credentialStore: FakeAIProviderCredentialStore(),
            httpClient: FakeHTTPClient()
        )

        let result = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        #expect(result == .failed(AIProviderConnectionTester.missingAPIKeyMessage))
    }

    @Test("diagnostic request includes event context redacts messages and excludes pod logs")
    func diagnosticRequestIncludesMinimalRedactedEventContext() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 200, body: Self.openAIResponse("## 🔍 **Possible causes**\nBackOff\n\n## 🛠️ **Actionable fixes**\n```bash\nkubectl describe pod checkout-7f9d -n api\n```"))
        let requester = AIEventDiagnosticRequester(credentialStore: store, httpClient: http)

        _ = await requester.diagnose(
            context: Self.sampleContext(events: [
                AIEventDiagnosticEvent(
                    reason: "BackOff",
                    namespace: "api",
                    objectKind: "Pod",
                    objectName: "checkout-7f9d",
                    message: "Authorization: Bearer sk-live-token password=super-secret",
                    observedAt: "2026-07-02T00:07:00Z",
                    count: 7
                )
            ]),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        let request = try #require(http.lastRequest)
        #expect(request.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test-secret")
        let body = try #require(request.httpBody)
        let jsonString = String(data: body, encoding: .utf8) ?? ""

        #expect(jsonString.contains("Diagnose these Kubernetes Warning Events"))
        #expect(jsonString.contains("prod"))
        #expect(jsonString.contains("api"))
        #expect(jsonString.contains("Pod"))
        #expect(jsonString.contains("checkout-7f9d"))
        #expect(jsonString.contains("BackOff"))
        #expect(jsonString.contains("2026-07-02T00:07:00Z"))
        #expect(jsonString.contains("🔍 **Possible causes**"))
        #expect(jsonString.contains("🛠️ **Actionable fixes**"))
        #expect(!jsonString.contains("sk-live-token"))
        #expect(!jsonString.contains("super-secret"))
        #expect(!jsonString.contains("Authorization: Bearer sk-live-token"))
        #expect(!jsonString.contains("Last 50 log lines"))
        #expect(!jsonString.contains("panic: heap exhausted"))
        #expect(!jsonString.contains("kubeconfig"))
        #expect(!jsonString.contains("Secret object"))
    }

    @Test("custom event prompt instructions are included with fixed safety context")
    func customEventPromptInstructionsAreIncludedWithFixedSafetyContext() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 200, body: Self.openAIResponse("## 🔍 **Possible causes**\nCause\n\n## 🛠️ **Actionable fixes**\nFix"))
        let requester = AIEventDiagnosticRequester(credentialStore: store, httpClient: http)

        _ = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(
                provider: .openAI,
                modelID: "gpt-4o-mini",
                eventPromptInstructions: "Custom Event instructions: focus on the newest warning."
            ),
            provider: .openAI
        )

        let body = try #require(http.lastRequest?.httpBody)
        let jsonString = String(data: body, encoding: .utf8) ?? ""
        #expect(jsonString.contains("Custom Event instructions: focus on the newest warning."))
        #expect(!jsonString.contains("Diagnose these Kubernetes Warning Events for a human operator."))
        #expect(jsonString.contains("Use only the provided event context"))
        #expect(jsonString.contains("Latest matching Warning Events, capped at 5 and redacted before submission"))
        #expect(jsonString.contains("Commands are suggestions only; the app will not execute them."))
        #expect(!jsonString.contains("Last 50 log lines"))
    }

    @Test("blank event prompt instructions fall back to default")
    func blankEventPromptInstructionsFallBackToDefault() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 200, body: Self.openAIResponse("## 🔍 **Possible causes**\nCause\n\n## 🛠️ **Actionable fixes**\nFix"))
        let requester = AIEventDiagnosticRequester(credentialStore: store, httpClient: http)

        _ = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(
                provider: .openAI,
                modelID: "gpt-4o-mini",
                eventPromptInstructions: "   \n  "
            ),
            provider: .openAI
        )

        let body = try #require(http.lastRequest?.httpBody)
        let jsonString = String(data: body, encoding: .utf8) ?? ""
        #expect(jsonString.contains("Diagnose these Kubernetes Warning Events for a human operator."))
    }

    @Test("diagnostic request limits event payload to latest five")
    func diagnosticRequestLimitsEventsToLatestFive() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 200, body: Self.openAIResponse("## 🔍 **Possible causes**\nCause\n\n## 🛠️ **Actionable fixes**\nFix"))
        let requester = AIEventDiagnosticRequester(credentialStore: store, httpClient: http)
        let events = (1...7).map { index in
            AIEventDiagnosticEvent(
                reason: "BackOff",
                namespace: "api",
                objectKind: "Pod",
                objectName: "checkout-7f9d",
                message: "event-\(index)",
                observedAt: "2026-07-02T00:0\(index):00Z",
                count: index
            )
        }

        _ = await requester.diagnose(
            context: Self.sampleContext(events: events),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        let body = try #require(http.lastRequest?.httpBody)
        let jsonString = String(data: body, encoding: .utf8) ?? ""
        #expect(!jsonString.contains("event-1"))
        #expect(!jsonString.contains("event-2"))
        #expect(jsonString.contains("event-3"))
        #expect(jsonString.contains("event-7"))
    }

    @Test("HTTP and transport failures redact secrets")
    func failuresRedactSecrets() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(throwError: LocalAIEventTestError("Authorization: Bearer sk-test-secret failed"))
        let requester = AIEventDiagnosticRequester(credentialStore: store, httpClient: http)

        let result = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        guard case let .failed(message) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect(message == AIEventDiagnosticRequester.transportFailureMessage)
        #expect(!message.contains("sk-test-secret"))
        #expect(!message.contains("Bearer"))
    }

    @Test("successful provider response returns Markdown diagnosis")
    func successfulProviderResponseReturnsMarkdownDiagnosis() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let markdown = "## 🔍 **Possible causes**\nLikely image pull backoff.\n\n## 🛠️ **Actionable fixes**\n```bash\nkubectl describe pod checkout-7f9d -n api\n```"
        let requester = AIEventDiagnosticRequester(
            credentialStore: store,
            httpClient: FakeHTTPClient(statusCode: 200, body: Self.openAIResponse(markdown))
        )

        let result = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        #expect(result == .success(markdown: markdown))
    }

    @Test("reasoning think blocks are stripped from event diagnosis")
    func eventReasoningThinkBlocksAreStripped() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let raw = """
        <think>The image pull is failing, so the pod stays in BackOff.</think>

        ## 🔍 **Possible causes**
        - ImagePullBackOff: registry credentials or tag mismatch.

        ## 🛠️ **Actionable fixes**
        ```bash
        kubectl describe pod checkout-7f9d -n api
        ```
        """
        let requester = AIEventDiagnosticRequester(
            credentialStore: store,
            httpClient: FakeHTTPClient(statusCode: 200, body: Self.openAIResponse(raw))
        )

        let result = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "deepseek-reasoner"),
            provider: .openAI
        )

        guard case let .success(markdown) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(!markdown.contains("<think>"))
        #expect(!markdown.contains("image pull is failing, so the pod"))
        #expect(markdown.contains("## 🔍 **Possible causes**"))
        #expect(markdown.contains("kubectl describe pod checkout-7f9d -n api"))
    }

    private static func sampleContext(
        events: [AIEventDiagnosticEvent] = [
            AIEventDiagnosticEvent(
                reason: "BackOff",
                namespace: "api",
                objectKind: "Pod",
                objectName: "checkout-7f9d",
                message: "Back-off restarting failed container",
                observedAt: "2026-07-02T00:07:00Z",
                count: 7
            )
        ]
    ) -> AIEventDiagnosticContext {
        AIEventDiagnosticContext(
            target: WarningEventDiagnosticTarget(
                contextName: "prod",
                namespace: "api",
                objectKind: "Pod",
                objectName: "checkout-7f9d",
                reason: "BackOff"
            ),
            events: events,
            isStale: false
        )
    }

    private static func openAIResponse(_ markdown: String) -> Data {
        let body: [String: Any] = [
            "choices": [["message": ["content": markdown]]]
        ]
        return (try? JSONSerialization.data(withJSONObject: body)) ?? Data()
    }
}

private struct LocalAIEventTestError: Error {
    let message: String
    init(_ message: String) { self.message = message }
}
