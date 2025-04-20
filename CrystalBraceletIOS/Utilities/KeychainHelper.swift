import Foundation           // ← adds Data, UUID, etc.
import Security

/// Thin wrapper around keychain‑services for two secrets: DeepSeek & OpenAI.
final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    private let service = "com.jerry.CrystalBraceletIOS"

    // MARK: – CRUD
    func save(_ value: String, for key: String) {
        let data = Data(value.utf8)                                // Data now resolves

        let query: [String:Any] = [ kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: key ]

        let attrs = [kSecValueData as String: data]

        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        } else {
            var add = query; add[kSecValueData as String] = data
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    func read(_ key: String) -> String? {
        let query: [String: Any] = [ kSecClass       as String: kSecClassGenericPassword,
                                     kSecAttrService as String: service,
                                     kSecAttrAccount as String: key,
                                     kSecReturnData  as String: true,
                                     kSecMatchLimit  as String: kSecMatchLimitOne ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,                               // Data now resolves
              let str  = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    func delete(_ key: String) {
        let q: [String:Any] = [ kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: service,
                                kSecAttrAccount as String: key ]
        SecItemDelete(q as CFDictionary)
    }
}

