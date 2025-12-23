import Foundation
import AsyncSwiftyNetworking

// MARK: - Network Manager

/// Centralized network configuration with mock session for demo.
/// Uses DemoMockURLSession with realistic random delays.
final class NetworkManager: @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = NetworkManager()
    
    // MARK: - Properties
    
    let client: NetworkClient
    let tokenStorage: KeychainExtendedTokenStorage
    
    /// Base URL for the API (used by mock session routing)
    let baseURL = "https://demo-api.example.com/v1"
    
    /// The mock session for demo purposes
    let mockSession: DemoMockURLSession
    
    // MARK: - Initialization
    
    private init() {
        // 1. Create mock session with random delays
        mockSession = DemoMockURLSession()
        mockSession.minDelayMs = 400    // Min 400ms
        mockSession.maxDelayMs = 1200   // Max 1.2s
        mockSession.errorRate = 0.03    // 3% error rate
        mockSession.simulateSlowResponses = true
        
        // 2. Create token storage
        tokenStorage = KeychainExtendedTokenStorage(
            service: Bundle.main.bundleIdentifier ?? "com.example.swiftuiexample",
            accessTokenAccount: "access_token",
            refreshTokenAccount: "refresh_token"
        )
        
        // 3. Create refresh handler
        let refreshHandler = AppTokenRefreshHandler(storage: tokenStorage)
        
        // 4. Create refresh interceptor
        let refreshInterceptor = RefreshTokenInterceptor(
            tokenStorage: tokenStorage,
            refreshHandler: refreshHandler
        )
        
        // 5. Create logging interceptor
        let loggingInterceptor = LoggingInterceptor(level: .verbose)
        
        // 6. Configure client with mock session
        client = URLSessionNetworkClient(
            session: mockSession,  // Use mock session
            configuration: .mobile,
            requestInterceptors: [
                refreshInterceptor,
                loggingInterceptor
            ],
            responseInterceptors: [
                refreshInterceptor,
                loggingInterceptor
            ]
        )
        
        print("🌐 NetworkManager initialized with DemoMockURLSession")
        print("   ├─ Delay range: \(mockSession.minDelayMs)-\(mockSession.maxDelayMs)ms")
        print("   ├─ Error rate: \(Int(mockSession.errorRate * 100))%")
        print("   └─ Slow responses: \(mockSession.simulateSlowResponses ? "enabled" : "disabled")")
    }
    
    // MARK: - Token Management
    
    func saveTokens(access: String, refresh: String) {
        tokenStorage.save(accessToken: access, refreshToken: refresh)
    }
    
    func clearTokens() {
        tokenStorage.clearAll()
    }
    
    var hasValidToken: Bool {
        tokenStorage.currentToken != nil
    }
    
    // MARK: - Demo Controls
    
    /// Adjusts the mock session delay range
    func setDelayRange(min: UInt64, max: UInt64) {
        mockSession.minDelayMs = min
        mockSession.maxDelayMs = max
    }
    
    /// Adjusts the simulated error rate
    func setErrorRate(_ rate: Double) {
        mockSession.errorRate = max(0, min(1, rate))
    }
}

// MARK: - Token Refresh Handler

final class AppTokenRefreshHandler: TokenRefreshHandler, @unchecked Sendable {
    
    private let storage: KeychainExtendedTokenStorage
    
    init(storage: KeychainExtendedTokenStorage) {
        self.storage = storage
    }
    
    func refreshToken() async throws -> String {
        print("🔄 Refreshing access token...")
        
        // Get the current refresh token
        guard storage.refreshToken != nil else {
            print("❌ No refresh token available")
            throw RefreshTokenError.refreshTokenExpired
        }
        
        // Simulate network delay for refresh
        try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_000_000_000))
        
        // Generate new tokens
        let newAccessToken = "refreshed-access-\(UUID().uuidString.prefix(8))"
        let newRefreshToken = "refreshed-refresh-\(UUID().uuidString.prefix(8))"
        
        // Save new tokens
        storage.save(accessToken: newAccessToken, refreshToken: newRefreshToken)
        
        print("✅ Token refreshed successfully")
        return newAccessToken
    }
    
    func onRefreshFailure(_ error: Error) async {
        print("❌ Token refresh failed: \(error)")
        
        // Clear all tokens
        storage.clearAll()
        
        // Notify app to show login screen
        await MainActor.run {
            NotificationCenter.default.post(name: .sessionExpired, object: nil)
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let sessionExpired = Notification.Name("sessionExpired")
}

