import Foundation

/// Injectable boundary for storing AI provider API keys in macOS Keychain.
///
/// Production access wraps `SecItem` in the app target; tests use an in-memory
/// fake. Keys are namespaced by `AIProvider` so switching providers never
/// overwrites another provider's key.
public protocol AIProviderCredentialStoring: Sendable {
    func loadAPIKey(for provider: AIProvider) throws -> String?
    func saveAPIKey(_ key: String, for provider: AIProvider) throws
    func deleteAPIKey(for provider: AIProvider) throws
}
