import Foundation

/// Result of a manually triggered AI provider Test Connection.
public enum AIProviderConnectionResult: Equatable, Sendable {
    case success
    case failed(String)
}

/// Tests AI provider connectivity using a minimal chat completion probe.
///
/// Test Connection sends a `max_tokens=1` `"ping"` request to the configured
/// provider. It validates the API key, Model ID, and (for OpenAI-compatible)
/// Base URL in a single round-trip. It never sends Kubernetes data — no warning
/// text, Pod logs, kubeconfig content, raw kubectl output, or cluster JSON.
public struct AIProviderConnectionTester: Sendable {
    public static let missingAPIKeyMessage = "Add an API key to test the connection."
    public static let missingModelIDMessage = "Add a model ID to test the connection."
    public static let missingBaseURLMessage = "Add a Base URL to test the connection."
    public static let credentialStoreErrorMessage = "Could not read the saved API key. Check macOS Keychain access."

    private let credentialStore: any AIProviderCredentialStoring
    private let httpClient: any HTTPClient

    public init(credentialStore: any AIProviderCredentialStoring, httpClient: any HTTPClient) {
        self.credentialStore = credentialStore
        self.httpClient = httpClient
    }

    public func testConnection(
        config: AIDiagnosticAssistantConfig,
        provider: AIProvider,
        apiKeyOverride: String? = nil
    ) async -> AIProviderConnectionResult {
        guard !config.modelID.isEmpty else {
            return .failed(Self.missingModelIDMessage)
        }

        let apiKey: String
        if let override = apiKeyOverride?.trimmingCharacters(in: .whitespacesAndNewlines), !override.isEmpty {
            apiKey = override
        } else {
            do {
                guard let stored = try credentialStore.loadAPIKey(for: provider), !stored.isEmpty else {
                    return .failed(Self.missingAPIKeyMessage)
                }
                apiKey = stored
            } catch {
                return .failed(Self.credentialStoreErrorMessage)
            }
        }

        guard let request = buildRequest(config: config, provider: provider, apiKey: apiKey) else {
            return .failed(Self.missingBaseURLMessage)
        }

        do {
            let (_, response) = try await httpClient.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failed("Could not read the provider response.")
            }
            return result(for: http.statusCode)
        } catch {
            return .failed(Self.transportFailureMessage())
        }
    }

    private func buildRequest(
        config: AIDiagnosticAssistantConfig,
        provider: AIProvider,
        apiKey: String
    ) -> URLRequest? {
        switch provider {
        case .openAI:
            return chatCompletionsRequest(
                url: "https://api.openai.com/v1/chat/completions",
                apiKey: apiKey,
                model: config.modelID,
                auth: .bearer
            )
        case .anthropic:
            return anthropicRequest(url: "https://api.anthropic.com/v1/messages", apiKey: apiKey, model: config.modelID)
        case .gemini:
            return geminiRequest(model: config.modelID, apiKey: apiKey)
        case .openAICompatible:
            guard let baseURL = config.baseURL?.trimmingCharacters(in: .whitespacesAndNewlines), !baseURL.isEmpty else {
                return nil
            }
            let normalized = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
            return chatCompletionsRequest(
                url: "\(normalized)/chat/completions",
                apiKey: apiKey,
                model: config.modelID,
                auth: .bearer
            )
        }
    }

    private enum AuthScheme {
        case bearer
    }

    private func chatCompletionsRequest(
        url: String,
        apiKey: String,
        model: String,
        auth: AuthScheme
    ) -> URLRequest? {
        guard let url = URL(string: url) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if auth == .bearer {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": "ping"]],
            "max_tokens": 1
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func anthropicRequest(url: String, apiKey: String, model: String) -> URLRequest? {
        guard let url = URL(string: url) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1,
            "messages": [["role": "user", "content": "ping"]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func geminiRequest(model: String, apiKey: String) -> URLRequest? {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent") else {
            return nil
        }
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let body: [String: Any] = [
            "contents": [["parts": [["text": "ping"]]]],
            "generationConfig": ["maxOutputTokens": 1]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func result(for statusCode: Int) -> AIProviderConnectionResult {
        switch statusCode {
        case 200..<300:
            return .success
        case 401, 403:
            return .failed("Authentication failed. Check your API key.")
        case 400..<500:
            return .failed("Request failed (HTTP \(statusCode)).")
        default:
            return .failed("Provider error (HTTP \(statusCode)). Try again later.")
        }
    }

    private static func transportFailureMessage() -> String {
        "Could not reach the provider. Check your network and Base URL."
    }
}
