import Foundation

public struct AIEventDiagnosticRequester: Sendable {
    public static let transportFailureMessage = "Could not reach the AI provider. Check your network and Base URL."
    public static let unreadableResponseMessage = "Could not read the AI diagnosis. Try again later."

    private let credentialStore: any AIProviderCredentialStoring
    private let httpClient: any HTTPClient

    public init(credentialStore: any AIProviderCredentialStoring, httpClient: any HTTPClient) {
        self.credentialStore = credentialStore
        self.httpClient = httpClient
    }

    public func diagnose(
        context: AIEventDiagnosticContext,
        config: AIDiagnosticAssistantConfig,
        provider: AIProvider
    ) async -> AIEventDiagnosticResult {
        guard !config.modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failed(AIProviderConnectionTester.missingModelIDMessage)
        }

        let apiKey: String
        do {
            guard let stored = try credentialStore.loadAPIKey(for: provider), !stored.isEmpty else {
                return .failed(AIProviderConnectionTester.missingAPIKeyMessage)
            }
            apiKey = stored
        } catch {
            return .failed(AIProviderConnectionTester.credentialStoreErrorMessage)
        }

        guard let request = buildRequest(config: config, provider: provider, apiKey: apiKey, context: context) else {
            return .failed(AIProviderConnectionTester.missingBaseURLMessage)
        }

        do {
            let (data, response) = try await httpClient.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failed(Self.unreadableResponseMessage)
            }

            guard (200..<300).contains(http.statusCode) else {
                return .failed(resultMessage(for: http.statusCode))
            }

            guard let markdown = markdown(from: data, provider: provider), !markdown.isEmpty else {
                return .failed(Self.unreadableResponseMessage)
            }

            let cleaned = AIDiagnosticResponseFormatter.cleanedMarkdown(from: markdown)
            guard !cleaned.isEmpty else {
                return .failed(Self.unreadableResponseMessage)
            }

            return .success(markdown: cleaned)
        } catch {
            return .failed(Self.transportFailureMessage)
        }
    }

    private func buildRequest(
        config: AIDiagnosticAssistantConfig,
        provider: AIProvider,
        apiKey: String,
        context: AIEventDiagnosticContext
    ) -> URLRequest? {
        let promptInstructions = config.effectiveEventPromptInstructions
        switch provider {
        case .openAI:
            return chatCompletionsRequest(
                url: "https://api.openai.com/v1/chat/completions",
                apiKey: apiKey,
                model: config.modelID,
                context: context,
                promptInstructions: promptInstructions
            )
        case .anthropic:
            return anthropicRequest(
                url: "https://api.anthropic.com/v1/messages",
                apiKey: apiKey,
                model: config.modelID,
                context: context,
                promptInstructions: promptInstructions
            )
        case .gemini:
            return geminiRequest(
                model: config.modelID,
                apiKey: apiKey,
                context: context,
                promptInstructions: promptInstructions
            )
        case .openAICompatible:
            guard let baseURL = config.baseURL?.trimmingCharacters(in: .whitespacesAndNewlines), !baseURL.isEmpty else {
                return nil
            }
            let normalized = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
            return chatCompletionsRequest(
                url: "\(normalized)/chat/completions",
                apiKey: apiKey,
                model: config.modelID,
                context: context,
                promptInstructions: promptInstructions
            )
        }
    }

    private func chatCompletionsRequest(
        url: String,
        apiKey: String,
        model: String,
        context: AIEventDiagnosticContext,
        promptInstructions: String
    ) -> URLRequest? {
        guard let url = URL(string: url) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 45)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": Self.systemPrompt],
                ["role": "user", "content": diagnosticPrompt(from: context, promptInstructions: promptInstructions)]
            ],
            "temperature": 0.2,
            "max_tokens": 900
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func anthropicRequest(
        url: String,
        apiKey: String,
        model: String,
        context: AIEventDiagnosticContext,
        promptInstructions: String
    ) -> URLRequest? {
        guard let url = URL(string: url) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 45)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "system": Self.systemPrompt,
            "max_tokens": 900,
            "messages": [["role": "user", "content": diagnosticPrompt(from: context, promptInstructions: promptInstructions)]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func geminiRequest(
        model: String,
        apiKey: String,
        context: AIEventDiagnosticContext,
        promptInstructions: String
    ) -> URLRequest? {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent") else {
            return nil
        }
        var request = URLRequest(url: url, timeoutInterval: 45)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let body: [String: Any] = [
            "contents": [[
                "parts": [["text": "\(Self.systemPrompt)\n\n\(diagnosticPrompt(from: context, promptInstructions: promptInstructions))"]]
            ]],
            "generationConfig": [
                "temperature": 0.2,
                "maxOutputTokens": 900
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func diagnosticPrompt(from context: AIEventDiagnosticContext, promptInstructions: String) -> String {
        let eventText = context.events
            .suffix(5)
            .enumerated()
            .map { index, event in
                """
                Event \(index + 1):
                - Reason: \(event.reason)
                - Namespace: \(event.namespace ?? "none")
                - Object: \(event.objectKind ?? "unknown")/\(event.objectName ?? "unknown")
                - Observed at: \(event.observedAt ?? "unknown")
                - Count: \(event.count)
                - Message: \(AIDiagnosticRedactor.redact(event.message ?? "No message"))
                """
            }
            .joined(separator: "\n")
        let staleText = context.isStale ? "stale" : "fresh"

        return """
        Prompt instructions:
        \(promptInstructions)

        Kubernetes diagnostic context supplied by Kubebar:
        Target warning group:
        - Context: \(context.target.contextName)
        - Namespace: \(context.target.namespace ?? "none")
        - Object kind: \(context.target.objectKind)
        - Object name: \(context.target.objectName)
        - Reason: \(context.target.reason)
        - Snapshot freshness: \(staleText)

        Latest matching Warning Events, capped at 5 and redacted before submission:
        \(eventText.isEmpty ? "- No matching warning events returned" : eventText)

        Safety reminders:
        - Use only the supplied event context above.
        - Commands are suggestions only; the app will not execute them.
        """
    }

    private func resultMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 401, 403:
            "Authentication failed. Check your API key."
        case 400..<500:
            "AI diagnosis request failed (HTTP \(statusCode))."
        default:
            "AI provider error (HTTP \(statusCode)). Try again later."
        }
    }

    private func markdown(from data: Data, provider: AIProvider) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        switch provider {
        case .openAI, .openAICompatible:
            let choices = object["choices"] as? [[String: Any]]
            let message = choices?.first?["message"] as? [String: Any]
            return (message?["content"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        case .anthropic:
            let content = object["content"] as? [[String: Any]]
            let text = content?
                .compactMap { $0["text"] as? String }
                .joined(separator: "\n")
            return text?.trimmingCharacters(in: .whitespacesAndNewlines)
        case .gemini:
            let candidates = object["candidates"] as? [[String: Any]]
            let content = candidates?.first?["content"] as? [String: Any]
            let parts = content?["parts"] as? [[String: Any]]
            let text = parts?
                .compactMap { $0["text"] as? String }
                .joined(separator: "\n")
            return text?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static let systemPrompt = "You are a concise Kubernetes incident assistant. Use only the provided event context. Do not claim you executed commands."
}
