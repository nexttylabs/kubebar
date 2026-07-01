import Foundation

/// Non-secret AI Diagnostic Assistant provider metadata.
///
/// `API key` material is intentionally excluded from this value type so it can
/// never be persisted through `AppConfig` or appear in `config.json`. Secret
/// credentials belong to the Keychain credential store introduced in a later
/// step.
public struct AIDiagnosticAssistantConfig: Codable, Equatable, Sendable {
    public let provider: AIProvider
    public var modelID: String
    public let baseURL: String?

    public init(
        provider: AIProvider = .openAI,
        modelID: String = "",
        baseURL: String? = nil
    ) {
        self.provider = provider
        self.modelID = modelID
        self.baseURL = baseURL
    }

    public func with(modelID: String) -> AIDiagnosticAssistantConfig {
        AIDiagnosticAssistantConfig(
            provider: provider,
            modelID: modelID,
            baseURL: baseURL
        )
    }

    public func with(baseURL: String?) -> AIDiagnosticAssistantConfig {
        AIDiagnosticAssistantConfig(
            provider: provider,
            modelID: modelID,
            baseURL: baseURL
        )
    }
}

/// Supported AI providers for the AI Diagnostic Assistant.
///
/// `openAICompatible` targets custom OpenAI-compatible endpoints that use only
/// Bearer authentication, a Base URL, and a Model ID. `ollama` is intentionally
/// not included in this version.
public enum AIProvider: String, Codable, Equatable, Sendable {
    case openAI
    case anthropic
    case gemini
    case openAICompatible
}
