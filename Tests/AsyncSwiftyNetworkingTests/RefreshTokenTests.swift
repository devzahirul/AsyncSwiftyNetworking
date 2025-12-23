import Testing
import Foundation
@testable import AsyncSwiftyNetworking

// MARK: - RefreshTokenInterceptor Tests

@Suite("RefreshTokenInterceptor Tests")
struct RefreshTokenInterceptorTests {
    
    // MARK: - Mock Refresh Handler
    
    final class MockRefreshHandler: TokenRefreshHandler, @unchecked Sendable {
        var refreshCallCount = 0
        var mockNewToken: String = "new-access-token"
        var shouldFail = false
        var failureError: Error = NetworkError.unauthorized
        var onRefreshFailureCalled = false
        
        func refreshToken() async throws -> String {
            refreshCallCount += 1
            if shouldFail {
                throw failureError
            }
            return mockNewToken
        }
        
        func onRefreshFailure(_ error: Error) async {
            onRefreshFailureCalled = true
        }
    }
    
    // MARK: - Tests
    
    @Test("Request interceptor adds current token to request")
    func testRequestInterceptorAddsToken() async throws {
        let storage = MockTokenStorage()
        storage.mockToken = "existing-token"
        
        let handler = MockRefreshHandler()
        let interceptor = RefreshTokenInterceptor(tokenStorage: storage, refreshHandler: handler)
        
        var request = URLRequest(url: URL(string: "https://api.test.com/users")!)
        request = try await interceptor.intercept(request)
        
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer existing-token")
    }
    
    @Test("Request interceptor handles nil token gracefully")
    func testRequestInterceptorWithNilToken() async throws {
        let storage = MockTokenStorage()
        storage.mockToken = nil
        
        let handler = MockRefreshHandler()
        let interceptor = RefreshTokenInterceptor(tokenStorage: storage, refreshHandler: handler)
        
        var request = URLRequest(url: URL(string: "https://api.test.com/users")!)
        request = try await interceptor.intercept(request)
        
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }
    
    @Test("Response interceptor passes through non-401 responses")
    func testPassthroughNon401() async throws {
        let storage = MockTokenStorage()
        let handler = MockRefreshHandler()
        let interceptor = RefreshTokenInterceptor(tokenStorage: storage, refreshHandler: handler)
        
        let response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        
        let originalData = "success".data(using: .utf8)!
        let result = try await interceptor.intercept(response, data: originalData)
        
        #expect(result == originalData)
        #expect(handler.refreshCallCount == 0)
    }
    
    @Test("Response interceptor triggers refresh on 401")
    func testRefreshOn401() async throws {
        let storage = MockTokenStorage()
        storage.mockToken = "old-token"
        
        let handler = MockRefreshHandler()
        handler.mockNewToken = "refreshed-token"
        
        let interceptor = RefreshTokenInterceptor(tokenStorage: storage, refreshHandler: handler)
        
        let response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: 401,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        
        do {
            _ = try await interceptor.intercept(response, data: Data())
            Issue.record("Expected tokenRefreshed error")
        } catch RefreshTokenError.tokenRefreshed {
            // Expected - token was refreshed
            #expect(handler.refreshCallCount == 1)
            #expect(storage.currentToken == "refreshed-token")
        }
    }
    
    @Test("Response interceptor calls onRefreshFailure when refresh fails")
    func testRefreshFailure() async throws {
        let storage = MockTokenStorage()
        let handler = MockRefreshHandler()
        handler.shouldFail = true
        handler.failureError = RefreshTokenError.refreshTokenExpired
        
        let interceptor = RefreshTokenInterceptor(tokenStorage: storage, refreshHandler: handler)
        
        let response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: 401,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        
        do {
            _ = try await interceptor.intercept(response, data: Data())
            Issue.record("Expected unauthorized error")
        } catch let error as NetworkError {
            #expect(error == .unauthorized)
            #expect(handler.onRefreshFailureCalled == true)
        }
    }
    
    // MARK: - Extended Token Storage Tests
    
    @Test("KeychainExtendedTokenStorage saves and retrieves both tokens")
    func testExtendedStorageSaveAndRetrieve() {
        let storage = KeychainExtendedTokenStorage(
            service: "test.refresh.\(UUID().uuidString)",
            accessTokenAccount: "access",
            refreshTokenAccount: "refresh"
        )
        
        // Clean up first
        storage.clearAll()
        
        // Save both tokens
        let saved = storage.save(accessToken: "access-123", refreshToken: "refresh-456")
        #expect(saved == true)
        
        // Verify both are stored
        #expect(storage.currentToken == "access-123")
        #expect(storage.refreshToken == "refresh-456")
        
        // Clean up
        storage.clearAll()
        #expect(storage.currentToken == nil)
        #expect(storage.refreshToken == nil)
    }
}
