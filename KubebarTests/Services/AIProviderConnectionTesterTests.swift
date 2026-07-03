import Foundation
import Testing
@testable import KubebarCore

@Suite("AI provider connection tester")
struct AIProviderConnectionTesterTests {
    @Test("missing API key returns safe local failure")
    func missingAPIKeyReturnsSafeLocalFailure() async {
        let tester = AIProviderConnectionTester(
            credentialStore: FakeAIProviderCredentialStore(),
            httpClient: FakeHTTPClient()
        )

        let result = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        guard case let .failed(message) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect(message == AIProviderConnectionTester.missingAPIKeyMessage)
    }

    @Test("missing model ID returns safe local failure")
    func missingModelIDReturnsSafeLocalFailure() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let tester = AIProviderConnectionTester(
            credentialStore: store,
            httpClient: FakeHTTPClient()
        )

        let result = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: ""),
            provider: .openAI
        )

        guard case let .failed(message) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect(message == AIProviderConnectionTester.missingModelIDMessage)
    }

    @Test("openAI compatible missing base URL returns safe local failure")
    func openAICompatibleMissingBaseURLReturnsSafeLocalFailure() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAICompatible)
        let tester = AIProviderConnectionTester(
            credentialStore: store,
            httpClient: FakeHTTPClient()
        )

        let result = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAICompatible, modelID: "gpt-4o-mini", baseURL: nil),
            provider: .openAICompatible
        )

        guard case let .failed(message) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect(message == AIProviderConnectionTester.missingBaseURLMessage)
    }

    @Test("openAI request uses Authorization Bearer and minimal body")
    func openAIRequestUsesAuthorizationBearerAndMinimalBody() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient()
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        _ = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        let request = try #require(http.lastRequest)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test-secret")
        #expect(request.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
        let body = try #require(request.httpBody)
        let json = try #require(try? JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["model"] as? String == "gpt-4o-mini")
        #expect(json["max_tokens"] as? Int == 1)
    }

    @Test("anthropic request uses provider-specific key and version headers")
    func anthropicRequestUsesProviderSpecificKeyAndVersionHeaders() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-ant-test", for: .anthropic)
        let http = FakeHTTPClient()
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        _ = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .anthropic, modelID: "claude-3"),
            provider: .anthropic
        )

        let request = try #require(http.lastRequest)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-ant-test")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        #expect(request.url?.absoluteString == "https://api.anthropic.com/v1/messages")
    }

    @Test("gemini request uses x-goog-api-key header not URL query")
    func geminiRequestUsesGoogAPIKeyHeaderNotURLQuery() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-gem-test", for: .gemini)
        let http = FakeHTTPClient()
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        _ = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .gemini, modelID: "gemini-1.5-flash"),
            provider: .gemini
        )

        let request = try #require(http.lastRequest)
        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "sk-gem-test")
        let urlString = request.url?.absoluteString ?? ""
        #expect(!urlString.contains("key="))
        #expect(!urlString.contains("sk-gem-test"))
        #expect(urlString.contains("gemini-1.5-flash:generateContent"))
    }

    @Test("openAI compatible request uses configured base URL with Bearer and no custom headers")
    func openAICompatibleRequestUsesConfiguredBaseURLWithBearer() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-custom", for: .openAICompatible)
        let http = FakeHTTPClient()
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        _ = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAICompatible, modelID: "gpt-4o-mini", baseURL: "https://example.test/v1"),
            provider: .openAICompatible
        )

        let request = try #require(http.lastRequest)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-custom")
        #expect(request.url?.absoluteString == "https://example.test/v1/chat/completions")
    }

    @Test("HTTP 200 returns success")
    func http200ReturnsSuccess() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 200)
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        let result = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        #expect(result == .success)
    }

    @Test("HTTP 401 returns authentication failed message")
    func http401ReturnsAuthenticationFailedMessage() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 401, body: Data("sk-test-secret leak".utf8))
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        let result = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        guard case let .failed(message) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect(message == "Authentication failed. Check your API key.")
        #expect(!message.contains("sk-test-secret"))
    }

    @Test("HTTP 500 returns provider error message")
    func http500ReturnsProviderErrorMessage() async {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 500, body: Data("sk-test-secret leak".utf8))
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        let result = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        guard case let .failed(message) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect(message == "Provider error (HTTP 500). Try again later.")
        #expect(!message.contains("sk-test-secret"))
    }

    @Test("test connection with draft key does not persist to credential store")
    func testConnectionWithDraftKeyDoesNotPersistToCredentialStore() async {
        let store = FakeAIProviderCredentialStore()
        let http = FakeHTTPClient(statusCode: 200)
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        _ = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI,
            apiKeyOverride: "sk-draft-secret"
        )

        #expect(store.saveCallCount == 0)
        #expect(store.loadCallCount == 0)
    }

    @Test("test connection with draft key uses draft in request")
    func testConnectionWithDraftKeyUsesDraftInRequest() async throws {
        let store = FakeAIProviderCredentialStore()
        let http = FakeHTTPClient(statusCode: 200)
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        _ = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI,
            apiKeyOverride: "sk-draft-secret"
        )

        let request = try #require(http.lastRequest)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-draft-secret")
    }

    @Test("test connection without draft key falls back to stored key")
    func testConnectionWithoutDraftKeyFallsBackToStoredKey() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-stored-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 200)
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        _ = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI,
            apiKeyOverride: nil
        )

        let request = try #require(http.lastRequest)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-stored-secret")
        #expect(store.loadCallCount == 1)
    }

    @Test("credential store load failure returns safe error not missing key")
    func credentialStoreLoadFailureReturnsSafeErrorNotMissingKey() async {
        let store = FakeAIProviderCredentialStore(shouldFailLoad: true)
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: FakeHTTPClient())

        let result = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI,
            apiKeyOverride: nil
        )

        guard case let .failed(message) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect(message == AIProviderConnectionTester.credentialStoreErrorMessage)
        #expect(message != AIProviderConnectionTester.missingAPIKeyMessage)
    }

    @Test("transport error redacts bearer token and key")
    func transportErrorRedactsBearerTokenAndKey() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(throwError: TestError("Authorization: Bearer sk-test-secret failed"))
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        let result = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(provider: .openAI, modelID: "gpt-4o-mini"),
            provider: .openAI
        )

        guard case let .failed(message) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect(message == "Could not reach the provider. Check your network and Base URL.")
        #expect(!message.contains("sk-test-secret"))
        #expect(!message.contains("Bearer"))
    }

    @Test("test connection sends no warning text or kubernetes data")
    func testConnectionSendsNoWarningTextOrKubernetesData() async throws {
        let store = FakeAIProviderCredentialStore()
        try? store.saveAPIKey("sk-test-secret", for: .openAI)
        let http = FakeHTTPClient(statusCode: 200)
        let tester = AIProviderConnectionTester(credentialStore: store, httpClient: http)

        _ = await tester.testConnection(
            config: AIDiagnosticAssistantConfig(
                provider: .openAI,
                modelID: "gpt-4o-mini",
                podPromptInstructions: "Custom Pod prompt should stay out of Test Connection",
                eventPromptInstructions: "Custom Event prompt should stay out of Test Connection"
            ),
            provider: .openAI
        )

        let body = try #require(http.lastRequest?.httpBody)
        let json = try #require(try? JSONSerialization.jsonObject(with: body) as? [String: Any])
        let messages = try #require(json["messages"] as? [[String: String]])
        let content = try #require(messages.first?["content"])
        #expect(content == "ping")
        let jsonString = String(data: body, encoding: .utf8) ?? ""
        #expect(!jsonString.contains("warning"))
        #expect(!jsonString.contains("kubectl"))
        #expect(!jsonString.contains("pod"))
        #expect(!jsonString.contains("Custom Pod prompt"))
        #expect(!jsonString.contains("Custom Event prompt"))
    }
}

// MARK: - Fakes

final class FakeAIProviderCredentialStore: AIProviderCredentialStoring, @unchecked Sendable {
    private var keys: [String: String] = [:]
    private(set) var saveCallCount = 0
    private(set) var loadCallCount = 0
    let shouldFailLoad: Bool
    let shouldFailSave: Bool

    init(shouldFailLoad: Bool = false, shouldFailSave: Bool = false) {
        self.shouldFailLoad = shouldFailLoad
        self.shouldFailSave = shouldFailSave
    }

    func loadAPIKey(for provider: AIProvider) throws -> String? {
        loadCallCount += 1
        if shouldFailLoad {
            throw FakeCredentialError()
        }
        return keys[provider.rawValue]
    }

    func saveAPIKey(_ key: String, for provider: AIProvider) throws {
        saveCallCount += 1
        if shouldFailSave {
            throw FakeCredentialError()
        }
        keys[provider.rawValue] = key
    }

    func deleteAPIKey(for provider: AIProvider) throws {
        keys.removeValue(forKey: provider.rawValue)
    }
}

private struct FakeCredentialError: Error {}

final class FakeHTTPClient: HTTPClient, @unchecked Sendable {
    private(set) var lastRequest: URLRequest?
    let statusCode: Int
    let body: Data
    let throwError: Error?

    init(statusCode: Int = 200, body: Data = Data(), throwError: Error? = nil) {
        self.statusCode = statusCode
        self.body = body
        self.throwError = throwError
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        if let throwError {
            throw throwError
        }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        return (body, response)
    }
}

private struct TestError: Error {
    let message: String
    init(_ message: String) { self.message = message }
}

extension TestError: LocalizedError {
    var errorDescription: String? { message }
}
