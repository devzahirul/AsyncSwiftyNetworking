import Foundation

/// Dependency Injection Container
/// Provides registration and resolution of dependencies with ViewModel caching
public final class DI: @unchecked Sendable {
    
    /// Shared singleton instance
    public static let shared = DI()
    
    // MARK: - Storage
    
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private var viewModels: [String: AnyObject] = [:]
    private let lock = NSLock()
    
    // MARK: - Configuration
    
    private var _baseURL: String = ""
    private var _tokenProvider: TokenProvider?
    private var _tokenStorage: TokenStorage?
    
    public var baseURL: String {
        get { _baseURL }
        set { _baseURL = newValue }
    }
    
    public var tokenProvider: TokenProvider? {
        get { _tokenProvider }
        set { _tokenProvider = newValue }
    }
    
    public var tokenStorage: TokenStorage? {
        get { _tokenStorage }
        set { _tokenStorage = newValue }
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Configure the DI container
    public static func configure(_ configure: (DI) -> Void) {
        configure(shared)
    }
    
    // MARK: - Registration
    
    /// Register a factory that creates a new instance each time
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        factories[key(for: type)] = factory
    }
    
    /// Register a singleton instance
    public func registerSingleton<T>(_ type: T.Type, instance: T) {
        lock.lock()
        defer { lock.unlock() }
        singletons[key(for: type)] = instance
    }
    
    // MARK: - Resolution
    
    /// Resolve a dependency
    public func resolve<T>(_ type: T.Type) -> T {
        lock.lock()
        defer { lock.unlock() }
        
        let key = key(for: type)
        
        // Check singletons first
        if let instance = singletons[key] as? T {
            return instance
        }
        
        // Use factory
        guard let factory = factories[key],
              let instance = factory() as? T else {
            fatalError("[\(type)] not registered in DI container")
        }
        
        return instance
    }
    
    /// Try to resolve, returns nil if not registered
    public func tryResolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        let key = key(for: type)
        
        if let instance = singletons[key] as? T {
            return instance
        }
        
        if let factory = factories[key],
           let instance = factory() as? T {
            return instance
        }
        
        return nil
    }
    
    // MARK: - ViewModel Store
    
    /// Get or create a ViewModel by type (cached)
    public func viewModel<VM: ObservableObject>(_ type: VM.Type, factory: () -> VM) -> VM {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        
        if let existing = viewModels[key] as? VM {
            return existing
        }
        
        let new = factory()
        viewModels[key] = new as AnyObject
        return new
    }
    
    /// Get or create a ViewModel by custom key (cached)
    public func viewModel<VM: ObservableObject>(key: String, factory: () -> VM) -> VM {
        lock.lock()
        defer { lock.unlock() }
        
        if let existing = viewModels[key] as? VM {
            return existing
        }
        
        let new = factory()
        viewModels[key] = new as AnyObject
        return new
    }
    
    /// Clear all cached ViewModels
    public func clearViewModels() {
        lock.lock()
        defer { lock.unlock() }
        viewModels.removeAll()
    }
    
    /// Clear a specific ViewModel by key
    public func clearViewModel(key: String) {
        lock.lock()
        defer { lock.unlock() }
        viewModels.removeValue(forKey: key)
    }
    
    // MARK: - Reset (for testing)
    
    /// Reset all registrations and caches
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        factories.removeAll()
        singletons.removeAll()
        viewModels.removeAll()
        _baseURL = ""
        _tokenProvider = nil
        _tokenStorage = nil
    }
    
    // MARK: - Helpers
    
    private func key<T>(for type: T.Type) -> String {
        String(describing: type)
    }
}

// MARK: - TokenProvider Protocol

/// Protocol for providing authentication tokens
public protocol TokenProvider: Sendable {
    /// The current access token, if available
    var accessToken: String? { get }
}
