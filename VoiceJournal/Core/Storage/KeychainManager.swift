import Foundation
import Security

// MARK: - Keychain Manager
actor KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.voicejournal.app"

    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    private init() {}

    // MARK: - Access Token
    func getAccessToken() -> String? {
        return read(key: Keys.accessToken)
    }

    func setAccessToken(_ token: String) {
        save(key: Keys.accessToken, value: token)
    }

    // MARK: - Refresh Token
    func getRefreshToken() -> String? {
        return read(key: Keys.refreshToken)
    }

    func setRefreshToken(_ token: String) {
        save(key: Keys.refreshToken, value: token)
    }

    // MARK: - Clear All
    func clearAll() {
        delete(key: Keys.accessToken)
        delete(key: Keys.refreshToken)
    }

    // MARK: - Private Methods
    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }

    private func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let isDarkMode = "isDarkMode"
        static let lastUserId = "lastUserId"
    }

    var hasCompletedOnboarding: Bool {
        get { bool(forKey: Keys.hasCompletedOnboarding) }
        set { set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    var isDarkModePreferred: Bool {
        get { bool(forKey: Keys.isDarkMode) }
        set { set(newValue, forKey: Keys.isDarkMode) }
    }

    var lastUserId: String? {
        get { string(forKey: Keys.lastUserId) }
        set { set(newValue, forKey: Keys.lastUserId) }
    }
}
