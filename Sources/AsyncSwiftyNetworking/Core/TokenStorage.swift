import Foundation

// MARK: - Token Storage Protocol

/// Protocol for abstracting token storage.
/// Allows swapping implementations (UserDefaults, Keychain, InMemory for tests).
/// Must be `Sendable` for safe concurrent access.
public protocol TokenStorage: AnyObject, Sendable {
    /// The current auth token, if any.
    var currentToken: String? { get }
    
    /// Saves a token.
    /// - Parameter token: The token to save.
    /// - Returns: Whether the save was successful.
    @discardableResult
    func save(_ token: String) -> Bool
    
    /// Clears the stored token.
    func clear()
}

// MARK: - Token Storage Container

/// A container that provides access to the current token storage.
/// Use this as a service locator for the active storage implementation.
/// - Important: For production apps, prefer dependency injection over this container.
public final class TokenStorageContainer: @unchecked Sendable {
    private static let lock = NSLock()
    private static var _shared: TokenStorage = KeychainTokenStorage()
    
    public static var shared: TokenStorage {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _shared
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _shared = newValue
        }
    }
}
