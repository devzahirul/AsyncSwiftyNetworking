import SwiftUI
import Combine

/// Central Auth State - publishes auth changes
/// LoginViewModel → saves token → AuthState notifies → Views update
@MainActor
public final class AuthState: ObservableObject {
    
    public static let shared = AuthState()
    
    // MARK: - Published State
    
    @Published public private(set) var isLoggedIn = false
    @Published public private(set) var currentUser: (any Sendable)?
    
    // MARK: - Internal Publisher
    
    private let authSubject = PassthroughSubject<AuthEvent, Never>()
    
    /// Publisher for auth events
    public var authEvents: AnyPublisher<AuthEvent, Never> {
        authSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Token Storage
    
    private var tokenStorage: TokenStorage? {
        DI.shared.tryResolve(TokenStorage.self)
    }
    
    private init() {
        // Check if already logged in
        checkAuthStatus()
    }
    
    // MARK: - Public Methods
    
    /// Called when login succeeds - updates auth state
    public func onLoginSuccess<User: Sendable>(token: String, user: User? = nil) {
        tokenStorage?.save(token)
        isLoggedIn = true
        currentUser = user
        authSubject.send(.loggedIn)
    }
    
    /// Called when logout - clears auth state
    public func logout() {
        tokenStorage?.clear()
        isLoggedIn = false
        currentUser = nil
        DI.shared.clearViewModels()
        authSubject.send(.loggedOut)
    }
    
    /// Called when session expires (401)
    public func onSessionExpired() {
        tokenStorage?.clear()
        isLoggedIn = false
        currentUser = nil
        authSubject.send(.sessionExpired)
    }
    
    /// Check current auth status
    public func checkAuthStatus() {
        isLoggedIn = tokenStorage?.currentToken != nil
    }
    
    // MARK: - Reset for Testing
    
    public func reset() {
        isLoggedIn = false
        currentUser = nil
    }
}

// MARK: - Auth Events

public enum AuthEvent: Sendable {
    case loggedIn
    case loggedOut
    case sessionExpired
}

// MARK: - AuthViewModel Protocol

/// Protocol for ViewModels that need auth state
@MainActor
public protocol AuthAwareViewModel: ObservableObject {
    var authState: AuthState { get }
    var isLoggedIn: Bool { get }
}

public extension AuthAwareViewModel {
    var authState: AuthState { AuthState.shared }
    var isLoggedIn: Bool { authState.isLoggedIn }
}

// MARK: - Updated Login ViewModel

/// Example: LoginViewModel that integrates with AuthState
@MainActor
open class AuthLoginViewModel<Request: Encodable, Response: HTTPResponseDecodable>: GenericMutationViewModel<Request, Response> {
    
    /// Override to extract token from response
    open func extractToken(from response: Response) -> String? {
        return nil
    }
    
    /// Override to extract user from response
    open func extractUser(from response: Response) -> (any Sendable)? {
        return nil
    }
    
    open override func onSuccess(_ response: Response) async {
        if let token = extractToken(from: response) {
            AuthState.shared.onLoginSuccess(token: token, user: extractUser(from: response))
        }
    }
}
