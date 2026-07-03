import Foundation

/// UI-facing state for the AI Diagnostic Assistant Settings section.
///
/// Holds the non-secret provider configuration and prompt editing fields plus
/// the transient API key draft and Test Connection result. The API key draft
/// is never persisted through `AppConfig`; it is saved to the Keychain
/// credential store only when Settings is saved.
public struct AIDiagnosticAssistantState: Equatable, Sendable {
    public var config: AIDiagnosticAssistantConfig
    public var apiKeyDraft: String
    public var testConnectionResult: AIProviderConnectionResult?

    public init(
        config: AIDiagnosticAssistantConfig = AIDiagnosticAssistantConfig(),
        apiKeyDraft: String = "",
        testConnectionResult: AIProviderConnectionResult? = nil
    ) {
        self.config = config
        self.apiKeyDraft = apiKeyDraft
        self.testConnectionResult = testConnectionResult
    }

    public var hasAPIKeyDraft: Bool {
        !apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var testConnectionMessage: String? {
        guard let result = testConnectionResult else {
            return nil
        }

        switch result {
        case .success:
            return "Connection successful."
        case let .failed(message):
            return message
        }
    }
}
