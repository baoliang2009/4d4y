import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    private let service = "com.fourd4y.hipda"

    private init() {}

    // MARK: - Save

    func save(data: Data, for key: String) -> Bool {
        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func save(string: String, for key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data: data, for: key)
    }

    // MARK: - Load

    func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }

    func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Delete

    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Account-specific helpers

    func saveCredentials(_ credentials: AccountCredentials) -> Bool {
        guard let data = try? JSONEncoder().encode(credentials) else { return false }
        return save(data: data, for: "credentials_\(credentials.accountId.uuidString)")
    }

    func loadCredentials(for accountId: UUID) -> AccountCredentials? {
        guard let data = load(key: "credentials_\(accountId.uuidString)") else { return nil }
        return try? JSONDecoder().decode(AccountCredentials.self, from: data)
    }

    func deleteCredentials(for accountId: UUID) {
        delete(key: "credentials_\(accountId.uuidString)")
    }
}