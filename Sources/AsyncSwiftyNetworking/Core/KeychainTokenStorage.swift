import Foundation
import Security

// MARK: - Keychain Token Storage

/// A secure implementation of `TokenStorage` using the iOS Keychain.
/// Thread-safe implementation using a serial queue for synchronization.
/// Recommended for production use with sensitive tokens.
public final class KeychainTokenStorage: TokenStorage, @unchecked Sendable {
    
    private let service: String
    private let account: String
    private let accessGroup: String?
    private let queue = DispatchQueue(label: "com.asyncswiftynetworking.keychain", qos: .userInitiated)
    
    /// Creates a new KeychainTokenStorage instance.
    /// - Parameters:
    ///   - service: The service name for the keychain item. Defaults to bundle identifier.
    ///   - account: The account name for the keychain item. Defaults to "auth_token".
    ///   - accessGroup: Optional access group for keychain sharing between apps.
    public init(
        service: String = Bundle.main.bundleIdentifier ?? "com.app.auth",
        account: String = "auth_token",
        accessGroup: String? = nil
    ) {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
    }
    
    public var currentToken: String? {
        queue.sync {
            readToken()
        }
    }
    
    @discardableResult
    public func save(_ token: String) -> Bool {
        queue.sync {
            // Delete any existing item first
            deleteToken()
            
            guard let data = token.data(using: .utf8) else { return false }
            
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
            
            if let accessGroup = accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }
            
            let status = SecItemAdd(query as CFDictionary, nil)
            return status == errSecSuccess
        }
    }
    
    public func clear() {
        queue.sync {
            _ = deleteToken()
        }
    }
    
    // MARK: - Private Helpers
    
    private func readToken() -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    @discardableResult
    private func deleteToken() -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
