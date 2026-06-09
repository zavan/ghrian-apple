import Foundation
import Security

/// Minimal generic-password Keychain wrapper for the single API token. Keyed by
/// service; an optional `accessGroup` enables sharing the item with the widget /
/// menu-bar extensions via a keychain-access-groups entitlement.
enum Keychain {
    private static func baseQuery(service: String, accessGroup: String?) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        return query
    }

    static func read(service: String, accessGroup: String?) -> String? {
        var query = baseQuery(service: service, accessGroup: accessGroup)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    static func write(_ value: String, service: String, accessGroup: String?) {
        let data = Data(value.utf8)
        let query = baseQuery(service: service, accessGroup: accessGroup)

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert.merge(attributes) { _, new in new }
            SecItemAdd(insert as CFDictionary, nil)
        }
    }

    static func delete(service: String, accessGroup: String?) {
        SecItemDelete(baseQuery(service: service, accessGroup: accessGroup) as CFDictionary)
    }
}
