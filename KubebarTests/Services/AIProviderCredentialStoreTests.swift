import Foundation
import Testing
@testable import KubebarCore

@Suite("AI provider credential store")
struct AIProviderCredentialStoreTests {
    @Test("missing key returns nil")
    func missingKeyReturnsNil() throws {
        let store = FakeAIProviderCredentialStore()

        #expect(try store.loadAPIKey(for: .openAI) == nil)
    }

    @Test("saved key loads back")
    func savedKeyLoadsBack() throws {
        let store = FakeAIProviderCredentialStore()
        try store.saveAPIKey("sk-test-secret", for: .openAI)

        #expect(try store.loadAPIKey(for: .openAI) == "sk-test-secret")
    }

    @Test("replacing key overwrites old value")
    func replacingKeyOverwritesOldValue() throws {
        let store = FakeAIProviderCredentialStore()
        try store.saveAPIKey("old-key", for: .anthropic)
        try store.saveAPIKey("new-key", for: .anthropic)

        #expect(try store.loadAPIKey(for: .anthropic) == "new-key")
    }

    @Test("deleting key removes only that provider slot")
    func deletingKeyRemovesOnlyThatProviderSlot() throws {
        let store = FakeAIProviderCredentialStore()
        try store.saveAPIKey("sk-openai", for: .openAI)
        try store.saveAPIKey("sk-anthropic", for: .anthropic)

        try store.deleteAPIKey(for: .openAI)

        try #expect(store.loadAPIKey(for: .openAI) == nil)
        try #expect(store.loadAPIKey(for: .anthropic) == "sk-anthropic")
    }

    @Test("each provider has its own slot")
    func eachProviderHasItsOwnSlot() throws {
        let store = FakeAIProviderCredentialStore()
        try store.saveAPIKey("sk-openai", for: .openAI)
        try store.saveAPIKey("sk-anthropic", for: .anthropic)
        try store.saveAPIKey("sk-gemini", for: .gemini)
        try store.saveAPIKey("sk-custom", for: .openAICompatible)

        try #expect(store.loadAPIKey(for: .openAI) == "sk-openai")
        try #expect(store.loadAPIKey(for: .anthropic) == "sk-anthropic")
        try #expect(store.loadAPIKey(for: .gemini) == "sk-gemini")
        try #expect(store.loadAPIKey(for: .openAICompatible) == "sk-custom")
    }
}
