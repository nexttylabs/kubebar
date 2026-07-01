import Foundation
import Security
import KubebarCore

/// Production Keychain-backed credential store for AI provider API keys.
///
/// Keys are namespaced by `AIProvider` raw value so switching providers
/// never overwrites another provider's key.
final class KeychainAIProviderCredentialStore: AIProviderCredentialStoring, @unchecked Sendable {
    private static let service = "com.nextty.kubebar.ai-provider"

    func loadAPIKey(for provider: AIProvider) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: provider.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
                return nil
            }
            return key
        case errSecItemNotFound:
            return nil
        default:
            throw AIProviderCredentialStoreError.cannotLoad
        }
    }

    func saveAPIKey(_ key: String, for provider: AIProvider) throws {
        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: provider.rawValue
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw AIProviderCredentialStoreError.cannotSave
            }
        default:
            throw AIProviderCredentialStoreError.cannotSave
        }
    }

    func deleteAPIKey(for provider: AIProvider) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: provider.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw AIProviderCredentialStoreError.cannotDelete
        }
    }
}

enum AIProviderCredentialStoreError: Error, Equatable {
    case cannotLoad
    case cannotSave
    case cannotDelete
}
