import Foundation

/// An interceptor that adds the Authorization header with a Bearer token.
/// Thread-safe implementation for concurrent use.
public final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    
    private let storage: TokenStorage
    
    /// Initializes the interceptor with a token storage.
    /// - Parameter storage: The token storage to read from. Defaults to the shared container.
    public init(storage: TokenStorage = TokenStorageContainer.shared) {
        self.storage = storage
    }
    
    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        var modifiedRequest = request
        
        if let token = storage.currentToken {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return modifiedRequest
    }
}
