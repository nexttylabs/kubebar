import Foundation

/// Non-secret AI Diagnostic Assistant provider metadata.
///
/// `API key` material is intentionally excluded from this value type so it can
/// never be persisted through `AppConfig` or appear in `config.json`. Secret
/// credentials belong to the Keychain credential store.
public struct AIDiagnosticAssistantConfig: Codable, Equatable, Sendable {
    public static let defaultPodPromptInstructions = """
    Diagnose this Kubernetes Pod for a human operator.

    Return concise Markdown with exactly these sections:
    ## 🔍 **Possible causes**
    - 2-4 likely causes grounded in the status, warnings, and logs.

    ## 🛠️ **Actionable fixes**
    - 2-5 practical next actions.
    - Include copy-ready kubectl command suggestions in fenced bash blocks when useful.
    - Commands are suggestions only; the app will not execute them.
    """

    public static let defaultEventPromptInstructions = """
    Diagnose these Kubernetes Warning Events for a human operator.

    Return concise Markdown with exactly these sections:
    ## 🔍 **Possible causes**
    - 2-4 likely causes grounded only in the Warning Events above.

    ## 🛠️ **Actionable fixes**
    - 2-5 practical next actions.
    - Include copy-ready kubectl command suggestions in fenced bash blocks when useful.
    - Commands are suggestions only; the app will not execute them.
    """

    public let provider: AIProvider
    public var modelID: String
    public let baseURL: String?
    public let podPromptInstructions: String?
    public let eventPromptInstructions: String?

    public init(
        provider: AIProvider = .openAI,
        modelID: String = "",
        baseURL: String? = nil,
        podPromptInstructions: String? = nil,
        eventPromptInstructions: String? = nil
    ) {
        self.provider = provider
        self.modelID = modelID
        self.baseURL = baseURL
        self.podPromptInstructions = Self.normalizedPromptOverride(podPromptInstructions)
        self.eventPromptInstructions = Self.normalizedPromptOverride(eventPromptInstructions)
    }

    public var effectivePodPromptInstructions: String {
        Self.normalizedPromptOverride(podPromptInstructions) ?? Self.defaultPodPromptInstructions
    }

    public var effectiveEventPromptInstructions: String {
        Self.normalizedPromptOverride(eventPromptInstructions) ?? Self.defaultEventPromptInstructions
    }

    public func with(modelID: String) -> AIDiagnosticAssistantConfig {
        AIDiagnosticAssistantConfig(
            provider: provider,
            modelID: modelID,
            baseURL: baseURL,
            podPromptInstructions: podPromptInstructions,
            eventPromptInstructions: eventPromptInstructions
        )
    }

    public func with(baseURL: String?) -> AIDiagnosticAssistantConfig {
        AIDiagnosticAssistantConfig(
            provider: provider,
            modelID: modelID,
            baseURL: baseURL,
            podPromptInstructions: podPromptInstructions,
            eventPromptInstructions: eventPromptInstructions
        )
    }

    public func with(provider: AIProvider) -> AIDiagnosticAssistantConfig {
        AIDiagnosticAssistantConfig(
            provider: provider,
            modelID: modelID,
            baseURL: baseURL,
            podPromptInstructions: podPromptInstructions,
            eventPromptInstructions: eventPromptInstructions
        )
    }

    public func with(podPromptInstructions: String?) -> AIDiagnosticAssistantConfig {
        AIDiagnosticAssistantConfig(
            provider: provider,
            modelID: modelID,
            baseURL: baseURL,
            podPromptInstructions: podPromptInstructions,
            eventPromptInstructions: eventPromptInstructions
        )
    }

    public func with(eventPromptInstructions: String?) -> AIDiagnosticAssistantConfig {
        AIDiagnosticAssistantConfig(
            provider: provider,
            modelID: modelID,
            baseURL: baseURL,
            podPromptInstructions: podPromptInstructions,
            eventPromptInstructions: eventPromptInstructions
        )
    }

    private static func normalizedPromptOverride(_ prompt: String?) -> String? {
        let trimmed = prompt?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else {
            return nil
        }

        return prompt
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
