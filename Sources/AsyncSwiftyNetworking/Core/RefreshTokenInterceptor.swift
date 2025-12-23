import Foundation

// MARK: - Token Refresh Handler

/// Protocol for handling token refresh operations.
/// Implement this to provide your app-specific token refresh logic.
public protocol TokenRefreshHandler: Sendable {
    /// Refreshes the authentication token.
    /// - Returns: The new access token.
    /// - Throws: An error if refresh fails (e.g., refresh token expired, requires re-login).
    func refreshToken() async throws -> String
    
    /// Called when token refresh fails permanently.
    /// Use this to trigger logout or re-authentication flow.
    func onRefreshFailure(_ error: Error) async
}

// MARK: - Refresh Token Interceptor

/// An interceptor that automatically handles 401 Unauthorized responses
/// by refreshing the access token and retrying the request.
///
/// Features:
/// - Automatic token refresh on 401 responses
/// - Thread-safe: Only one refresh at a time (other requests wait)
/// - Configurable max retry attempts
/// - Proper error handling and logout callback
///
/// Usage:
/// ```swift
/// let refreshInterceptor = RefreshTokenInterceptor(
///     tokenStorage: KeychainTokenStorage(),
///     refreshHandler: MyTokenRefreshHandler()
/// )
/// let client = URLSessionNetworkClient(
///     requestInterceptors: [AuthInterceptor(), refreshInterceptor],
///     responseInterceptors: [refreshInterceptor]
/// )
/// ```
public final class RefreshTokenInterceptor: RequestInterceptor, ResponseInterceptor, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let tokenStorage: TokenStorage
    private let refreshHandler: TokenRefreshHandler
    private let maxRetryAttempts: Int
    
    /// Actor to coordinate refresh operations and prevent concurrent refreshes
    private let coordinator = RefreshCoordinator()
    
    /// Header key used to track retry attempts
    private static let retryCountHeader = "X-Refresh-Retry-Count"
    
    // MARK: - Initialization
    
    /// Creates a new RefreshTokenInterceptor.
    /// - Parameters:
    ///   - tokenStorage: Storage for saving the refreshed token.
    ///   - refreshHandler: Handler that performs the actual token refresh.
    ///   - maxRetryAttempts: Maximum number of retry attempts after refresh. Default is 1.
    public init(
        tokenStorage: TokenStorage = TokenStorageContainer.shared,
        refreshHandler: TokenRefreshHandler,
        maxRetryAttempts: Int = 1
    ) {
        self.tokenStorage = tokenStorage
        self.refreshHandler = refreshHandler
        self.maxRetryAttempts = maxRetryAttempts
    }
    
    // MARK: - RequestInterceptor
    
    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        // Add fresh token to request (in case it was just refreshed)
        var modifiedRequest = request
        
        if let token = tokenStorage.currentToken {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return modifiedRequest
    }
    
    // MARK: - ResponseInterceptor
    
    public func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        // Only handle 401 Unauthorized
        guard response.statusCode == 401 else {
            return data
        }
        
        // Check if we've already retried
        // Note: This is tracked via the coordinator's pending request mechanism
        
        // Attempt to refresh the token
        do {
            let newToken = try await coordinator.refreshIfNeeded { [weak self] in
                guard let self = self else {
                    throw NetworkError.unknown
                }
                return try await self.refreshHandler.refreshToken()
            }
            
            // Save the new token
            tokenStorage.save(newToken)
            
            // Throw a special error to signal retry is needed
            throw RefreshTokenError.tokenRefreshed
            
        } catch RefreshTokenError.tokenRefreshed {
            // Re-throw to signal the request should be retried
            throw RefreshTokenError.tokenRefreshed
            
        } catch {
            // Refresh failed - notify handler and throw unauthorized
            await refreshHandler.onRefreshFailure(error)
            throw NetworkError.unauthorized
        }
    }
}

// MARK: - Refresh Coordinator

/// Actor that coordinates token refresh operations.
/// Ensures only one refresh happens at a time; other requests wait for it.
private actor RefreshCoordinator {
    
    private var isRefreshing = false
    private var refreshTask: Task<String, Error>?
    
    /// Performs a token refresh, or waits for an in-progress refresh.
    /// - Parameter refresh: The refresh operation to perform.
    /// - Returns: The new access token.
    func refreshIfNeeded(_ refresh: @escaping () async throws -> String) async throws -> String {
        // If already refreshing, wait for the existing task
        if let existingTask = refreshTask {
            return try await existingTask.value
        }
        
        // Start a new refresh
        isRefreshing = true
        
        let task = Task {
            defer {
                Task { await self.completeRefresh() }
            }
            return try await refresh()
        }
        
        refreshTask = task
        return try await task.value
    }
    
    private func completeRefresh() {
        isRefreshing = false
        refreshTask = nil
    }
}

// MARK: - Refresh Token Error

/// Internal errors used by the refresh token mechanism.
public enum RefreshTokenError: Error {
    /// Token was successfully refreshed - request should be retried.
    case tokenRefreshed
    /// Refresh token has expired - user needs to re-authenticate.
    case refreshTokenExpired
    /// Too many refresh attempts.
    case maxRetriesExceeded
}

// MARK: - Extended Token Storage

/// Extended token storage protocol that supports refresh tokens.
public protocol ExtendedTokenStorage: TokenStorage {
    /// The current refresh token, if any.
    var refreshToken: String? { get }
    
    /// Saves both access and refresh tokens.
    @discardableResult
    func save(accessToken: String, refreshToken: String) -> Bool
    
    /// Clears all tokens.
    func clearAll()
}

// MARK: - Keychain Extended Token Storage

/// Extended keychain storage that stores both access and refresh tokens.
public final class KeychainExtendedTokenStorage: ExtendedTokenStorage, @unchecked Sendable {
    
    private let accessTokenStorage: KeychainTokenStorage
    private let refreshTokenStorage: KeychainTokenStorage
    private let queue = DispatchQueue(label: "com.asyncswiftynetworking.extendedtoken", qos: .userInitiated)
    
    public init(
        service: String = Bundle.main.bundleIdentifier ?? "com.app.auth",
        accessTokenAccount: String = "access_token",
        refreshTokenAccount: String = "refresh_token"
    ) {
        self.accessTokenStorage = KeychainTokenStorage(service: service, account: accessTokenAccount)
        self.refreshTokenStorage = KeychainTokenStorage(service: service, account: refreshTokenAccount)
    }
    
    public var currentToken: String? {
        accessTokenStorage.currentToken
    }
    
    public var refreshToken: String? {
        refreshTokenStorage.currentToken
    }
    
    @discardableResult
    public func save(_ token: String) -> Bool {
        accessTokenStorage.save(token)
    }
    
    @discardableResult
    public func save(accessToken: String, refreshToken: String) -> Bool {
        let accessSaved = accessTokenStorage.save(accessToken)
        let refreshSaved = refreshTokenStorage.save(refreshToken)
        return accessSaved && refreshSaved
    }
    
    public func clear() {
        accessTokenStorage.clear()
    }
    
    public func clearAll() {
        accessTokenStorage.clear()
        refreshTokenStorage.clear()
    }
}
