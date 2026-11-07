// Day 15: Authentication & session management
// Independent educational example. Read lessons/day-15.md for setup.
// Add this file to an iOS app target. It uses Foundation and Security and does not depend on a storyboard or SwiftUI.
// Create one store with a stable reverse-DNS service such as com.example.PocketTasks.auth. Use a unique service in each test so exercises cannot overwrite a real account's item.
// Call try await store.save("fixture-only"), then try await store.read(), and finally try await store.delete() from an async function. Compare values in a test; do not print real tokens.
// The update-first path handles replacing an existing token. A missing item falls back to add, with an explicit device-local accessibility policy.
// This stores one refresh token. Multiple accounts, access groups, refresh-token rotation, biometric access control, and the server exchange need additional product-specific design.

import Foundation
import Security

enum TokenStoreError: Error {
    case status(OSStatus)
    case invalidData
}

actor RefreshTokenStore {
    private let service: String
    private let account = "refresh-token"

    init(service: String) {
        self.service = service
    }

    private var identity: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    func save(_ token: String) throws {
        let data = Data(token.utf8)
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(
            identity as CFDictionary,
            update as CFDictionary
        )
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else {
            throw TokenStoreError.status(status)
        }

        var item = identity
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] =
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let added = SecItemAdd(item as CFDictionary, nil)
        guard added == errSecSuccess else {
            throw TokenStoreError.status(added)
        }
    }

    func read() throws -> String? {
        var query = identity
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(
            query as CFDictionary, &result
        )
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw TokenStoreError.status(status)
        }
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8)
        else { throw TokenStoreError.invalidData }
        return token
    }

    func delete() throws {
        let status = SecItemDelete(identity as CFDictionary)
        guard status == errSecSuccess ||
              status == errSecItemNotFound else {
            throw TokenStoreError.status(status)
        }
    }
}
