import Foundation

// MARK: - UserDefaults Token Storage

/// A concrete implementation of `TokenStorage` using UserDefaults.
/// Thread-safe implementation suitable for non-sensitive tokens or development.
public final class UserDefaultsTokenStorage: TokenStorage, @unchecked Sendable {
    
    private let key: String
    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "com.asyncswiftynetworking.userdefaults", qos: .userInitiated)
    
    /// Creates a new UserDefaultsTokenStorage instance.
    /// - Parameters:
    ///   - key: The key used to store the token.
    ///   - defaults: The UserDefaults instance to use.
    public init(key: String = "auth_token", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }
    
    public var currentToken: String? {
        queue.sync {
            defaults.string(forKey: key)
        }
    }
    
    @discardableResult
    public func save(_ token: String) -> Bool {
        queue.sync {
            defaults.set(token, forKey: key)
            return defaults.synchronize()
        }
    }
    
    public func clear() {
        queue.sync {
            defaults.removeObject(forKey: key)
        }
    }
}
