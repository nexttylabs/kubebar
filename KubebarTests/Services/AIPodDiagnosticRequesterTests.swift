import Foundation
import Testing
@testable import KubebarCore

@Suite("AI Pod diagnostic requester")
struct AIPodDiagnosticRequesterTests {
    @Test("missing model ID returns safe local failure")
    func missingModelIDReturnsSafeLocalFailure() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let requester = AIPodDiagnosticRequester(credentialStore: store, httpClient: FakeHTTPClient())

        let result = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: ""),
            provider: .openAI
        )

        #expect(result == .failed(AIProviderConnectionTester.missingModelIDMessage))
    }

    @Test("missing API key returns safe local failure")
    func missingAPIKeyReturnsSafeLocalFailure() async {
        let requester = AIPodDiagnosticRequester(
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

    @Test("OpenAI-compatible missing base URL returns safe local failure")
    func openAICompatibleMissingBaseURLReturnsSafeLocalFailure() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAICompatible)
        let requester = AIPodDiagnosticRequester(credentialStore: store, httpClient: FakeHTTPClient())

        let result = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(provider: .openAICompatible, modelID: "gpt-4o-mini"),
            provider: .openAICompatible
        )

        #expect(result == .failed(AIProviderConnectionTester.missingBaseURLMessage))
    }

    @Test("diagnostic request includes pod context warnings redacted logs and required headings")
    func diagnosticRequestIncludesMinimalRedactedContext() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 200, body: Self.openAIResponse("## 🔍 **Possible causes**\nOOMKilled\n\n## 🛠️ **Actionable fixes**\n```bash\nkubectl describe pod checkout-7f9d -n api\n```"))
        let requester = AIPodDiagnosticRequester(credentialStore: store, httpClient: http)

        _ = await requester.diagnose(
            context: Self.sampleContext(logLines: [
                "starting checkout",
                "Authorization: Bearer sk-live-token",
                "password=super-secret",
                "panic: heap exhausted"
            ]),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        let request = try #require(http.lastRequest)
        #expect(request.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test-secret")
        let body = try #require(request.httpBody)
        let jsonString = String(data: body, encoding: .utf8) ?? ""

        #expect(jsonString.contains("prod"))
        #expect(jsonString.contains("api"))
        #expect(jsonString.contains("checkout-7f9d"))
        #expect(jsonString.contains("CrashLoopBackOff"))
        #expect(jsonString.contains("BackOff"))
        #expect(jsonString.contains("panic: heap exhausted"))
        #expect(jsonString.contains("🔍 **Possible causes**"))
        #expect(jsonString.contains("🛠️ **Actionable fixes**"))
        #expect(!jsonString.contains("sk-live-token"))
        #expect(!jsonString.contains("super-secret"))
        #expect(!jsonString.contains("Authorization: Bearer sk-live-token"))
        #expect(!jsonString.contains("kubeconfig"))
        #expect(!jsonString.contains("Secret object"))
    }

    @Test("custom pod prompt instructions are included with fixed safety context")
    func customPodPromptInstructionsAreIncludedWithFixedSafetyContext() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 200, body: Self.openAIResponse("## 🔍 **Possible causes**\nCause\n\n## 🛠️ **Actionable fixes**\nFix"))
        let requester = AIPodDiagnosticRequester(credentialStore: store, httpClient: http)

        _ = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(
                provider: .openAI,
                modelID: "gpt-4o-mini",
                podPromptInstructions: "Custom Pod instructions: answer in one paragraph."
            ),
            provider: .openAI
        )

        let body = try #require(http.lastRequest?.httpBody)
        let jsonString = String(data: body, encoding: .utf8) ?? ""
        #expect(jsonString.contains("Custom Pod instructions: answer in one paragraph."))
        #expect(!jsonString.contains("Diagnose this Kubernetes Pod for a human operator."))
        #expect(jsonString.contains("Use only the provided context"))
        #expect(jsonString.contains("Last 50 log lines, redacted before submission"))
        #expect(jsonString.contains("Commands are suggestions only; the app will not execute them."))
    }

    @Test("blank pod prompt instructions fall back to default")
    func blankPodPromptInstructionsFallBackToDefault() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 200, body: Self.openAIResponse("## 🔍 **Possible causes**\nCause\n\n## 🛠️ **Actionable fixes**\nFix"))
        let requester = AIPodDiagnosticRequester(credentialStore: store, httpClient: http)

        _ = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(
                provider: .openAI,
                modelID: "gpt-4o-mini",
                podPromptInstructions: "   \n  "
            ),
            provider: .openAI
        )

        let body = try #require(http.lastRequest?.httpBody)
        let jsonString = String(data: body, encoding: .utf8) ?? ""
        #expect(jsonString.contains("Diagnose this Kubernetes Pod for a human operator."))
    }

    @Test("diagnostic request limits logs to last fifty lines")
    func diagnosticRequestLimitsLogsToLastFiftyLines() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 200, body: Self.openAIResponse("## 🔍 **Possible causes**\nCause\n\n## 🛠️ **Actionable fixes**\nFix"))
        let requester = AIPodDiagnosticRequester(credentialStore: store, httpClient: http)
        let logLines = (1...60).map { "line-\($0)" }

        _ = await requester.diagnose(
            context: Self.sampleContext(logLines: logLines),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        let body = try #require(http.lastRequest?.httpBody)
        let jsonString = String(data: body, encoding: .utf8) ?? ""
        #expect(!jsonString.contains("line-9"))
        #expect(!jsonString.contains("line-10"))
        #expect(jsonString.contains("line-11"))
        #expect(jsonString.contains("line-60"))
    }

    @Test("HTTP and transport failures redact secrets")
    func failuresRedactSecrets() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(throwError: LocalTestError("Authorization: Bearer sk-test-secret failed"))
        let requester = AIPodDiagnosticRequester(credentialStore: store, httpClient: http)

        let result = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        guard case let .failed(message) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect(message == AIPodDiagnosticRequester.transportFailureMessage)
        #expect(!message.contains("sk-test-secret"))
        #expect(!message.contains("Bearer"))
    }

    @Test("successful provider response returns Markdown diagnosis")
    func successfulProviderResponseReturnsMarkdownDiagnosis() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let markdown = "## 🔍 **Possible causes**\nLikely OOMKilled.\n\n## 🛠️ **Actionable fixes**\n```bash\nkubectl describe pod checkout-7f9d -n api\n```"
        let requester = AIPodDiagnosticRequester(
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

    @Test("reasoning think blocks are stripped before reaching the UI")
    func reasoningThinkBlocksAreStripped() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let raw = """
         <think>
        The exit code 137 suggests an OOMKill. I should mention memory limits.
         </think>

        ## 🔍 **Possible causes**
        - OOMKilled: container exceeded its memory limit.

        ## 🛠️ **Actionable fixes**
        ```bash
        kubectl describe pod checkout-7f9d -n api
        ```
        """
        let requester = AIPodDiagnosticRequester(
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
        #expect(!markdown.contains(" <think>"))
        #expect(!markdown.contains("I should mention memory limits"))
        #expect(markdown.contains("## 🔍 **Possible causes**"))
        #expect(markdown.contains("kubectl describe pod checkout-7f9d -n api"))
    }

    @Test("response that is only reasoning returns an unreadable failure")
    func responseThatIsOnlyReasoningReturnsUnreadableFailure() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let raw = " <think>The pod is crashing but I never produced a final answer."
        let requester = AIPodDiagnosticRequester(
            credentialStore: store,
            httpClient: FakeHTTPClient(statusCode: 200, body: Self.openAIResponse(raw))
        )

        let result = await requester.diagnose(
            context: Self.sampleContext(),
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "deepseek-reasoner"),
            provider: .openAI
        )

        #expect(result == .failed(AIPodDiagnosticRequester.unreadableResponseMessage))
    }

    private static func sampleContext(logLines: [String] = ["panic: heap exhausted"]) -> AIPodDiagnosticContext {
        AIPodDiagnosticContext(
            target: PodLogTarget(contextName: "prod", namespace: "api", podName: "checkout-7f9d"),
            podStatus: AIPodStatusContext(
                state: "Bad",
                ready: "0/1 ready",
                reason: "CrashLoopBackOff",
                detail: "Container terminated with exit code 137"
            ),
            warnings: [
                AIPodWarningContext(
                    reason: "BackOff",
                    location: "api/pod/checkout-7f9d",
                    age: "2m ago",
                    message: "Back-off restarting failed container"
                )
            ],
            logLines: logLines,
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

private struct LocalTestError: Error {
    let message: String
    init(_ message: String) { self.message = message }
}
