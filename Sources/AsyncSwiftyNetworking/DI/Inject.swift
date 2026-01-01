import Foundation

/// Property wrapper for dependency injection
/// Usage: @Inject var service: MyService
@propertyWrapper
public struct Inject<T> {
    
    private var resolved: T?
    private let type: T.Type
    
    public init() {
        self.type = T.self
    }
    
    public var wrappedValue: T {
        mutating get {
            if resolved == nil {
                resolved = DI.shared.resolve(type)
            }
            // resolve() uses fatalError for missing registrations,
            // so resolved is guaranteed non-nil at this point
            guard let value = resolved else {
                fatalError("[\(T.self)] DI resolution returned nil unexpectedly")
            }
            return value
        }
    }
}
