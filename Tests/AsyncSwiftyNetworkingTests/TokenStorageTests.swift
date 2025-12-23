import Testing
import Foundation
@testable import AsyncSwiftyNetworking

// MARK: - TokenStorage Tests

@Suite("TokenStorage Tests")
struct TokenStorageTests {
    
    // MARK: - MockTokenStorage Tests
    
    @Test("MockTokenStorage stores and retrieves token")
    func testMockTokenStorageBasic() {
        let storage = MockTokenStorage()
        
        #expect(storage.currentToken == nil)
        
        storage.save("test-token")
        #expect(storage.currentToken == "test-token")
        
        storage.clear()
        #expect(storage.currentToken == nil)
    }
    
    @Test("MockTokenStorage tracks saved tokens")
    func testMockTokenStorageTracksSaves() {
        let storage = MockTokenStorage()
        
        storage.save("token1")
        storage.save("token2")
        storage.save("token3")
        
        #expect(storage.savedTokens.count == 3)
        #expect(storage.savedTokens == ["token1", "token2", "token3"])
        #expect(storage.currentToken == "token3")
    }
    
    @Test("MockTokenStorage tracks clear calls")
    func testMockTokenStorageTracksClear() {
        let storage = MockTokenStorage()
        
        storage.clear()
        storage.clear()
        storage.clear()
        
        #expect(storage.clearCallCount == 3)
    }
    
    @Test("MockTokenStorage reset clears all state")
    func testMockTokenStorageReset() {
        let storage = MockTokenStorage()
        
        storage.save("token")
        storage.clear()
        
        #expect(storage.savedTokens.count == 1)
        #expect(storage.clearCallCount == 1)
        
        storage.reset()
        
        #expect(storage.currentToken == nil)
        #expect(storage.savedTokens.isEmpty)
        #expect(storage.clearCallCount == 0)
    }
    
    // MARK: - UserDefaultsTokenStorage Tests
    
    @Test("UserDefaultsTokenStorage stores and retrieves token")
    func testUserDefaultsTokenStorage() {
        // Use a unique key to avoid conflicts
        let key = "test_token_\(UUID().uuidString)"
        let storage = UserDefaultsTokenStorage(key: key)
        
        // Clean up any existing value
        storage.clear()
        #expect(storage.currentToken == nil)
        
        storage.save("user-defaults-token")
        #expect(storage.currentToken == "user-defaults-token")
        
        // Clean up
        storage.clear()
        #expect(storage.currentToken == nil)
    }
    
    @Test("UserDefaultsTokenStorage uses correct key")
    func testUserDefaultsTokenStorageKey() {
        let key = "custom_key_\(UUID().uuidString)"
        let defaults = UserDefaults.standard
        let storage = UserDefaultsTokenStorage(key: key, defaults: defaults)
        
        storage.save("test-value")
        
        // Verify value is stored in UserDefaults
        #expect(defaults.string(forKey: key) == "test-value")
        
        // Clean up
        storage.clear()
    }
    
    // MARK: - TokenStorageContainer Tests
    
    @Test("TokenStorageContainer can be replaced")
    func testTokenStorageContainer() {
        // Save original
        let original = TokenStorageContainer.shared
        
        // Replace with mock
        let mockStorage = MockTokenStorage()
        mockStorage.mockToken = "container-token"
        TokenStorageContainer.shared = mockStorage
        
        #expect(TokenStorageContainer.shared.currentToken == "container-token")
        
        // Restore original
        TokenStorageContainer.shared = original
    }
}

// MARK: - NetworkConfiguration Tests

@Suite("NetworkConfiguration Tests")
struct NetworkConfigurationTests {
    
    @Test("Default configuration has sensible values")
    func testDefaultConfiguration() {
        let config = NetworkConfiguration.default
        
        #expect(config.timeoutInterval == 30)
        #expect(config.retryPolicy == .none)
        #expect(config.cachePolicy == .useProtocolCachePolicy)
    }
    
    @Test("Mobile configuration has retry enabled")
    func testMobileConfiguration() {
        let config = NetworkConfiguration.mobile
        
        #expect(config.timeoutInterval == 60)
        #expect(config.cachePolicy == .returnCacheDataElseLoad)
        
        if case .exponentialBackoff(let maxRetries, let baseDelay) = config.retryPolicy {
            #expect(maxRetries == 3)
            #expect(baseDelay == 1.0)
        } else {
            Issue.record("Expected exponentialBackoff retry policy")
        }
    }
    
    @Test("Custom configuration values")
    func testCustomConfiguration() {
        let config = NetworkConfiguration(
            timeoutInterval: 45,
            retryPolicy: .fixed(maxRetries: 2, delay: 0.5),
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        
        #expect(config.timeoutInterval == 45)
        #expect(config.cachePolicy == .reloadIgnoringLocalCacheData)
        
        if case .fixed(let maxRetries, let delay) = config.retryPolicy {
            #expect(maxRetries == 2)
            #expect(delay == 0.5)
        } else {
            Issue.record("Expected fixed retry policy")
        }
    }
}

// MARK: - RetryPolicy Tests

@Suite("RetryPolicy Tests")
struct RetryPolicyTests {
    
    @Test("None policy has zero retries")
    func testNonePolicy() {
        let policy = RetryPolicy.none
        #expect(policy.maxRetries == 0)
    }
    
    @Test("ExponentialBackoff maxRetries")
    func testExponentialBackoffMaxRetries() {
        let policy = RetryPolicy.exponentialBackoff(maxRetries: 5, baseDelay: 1.0)
        #expect(policy.maxRetries == 5)
    }
    
    @Test("Fixed maxRetries")
    func testFixedMaxRetries() {
        let policy = RetryPolicy.fixed(maxRetries: 3, delay: 2.0)
        #expect(policy.maxRetries == 3)
    }
    
    @Test("ExponentialBackoff delay calculation")
    func testExponentialBackoffDelay() {
        let policy = RetryPolicy.exponentialBackoff(maxRetries: 5, baseDelay: 1.0)
        
        #expect(policy.delay(for: 0) == 1.0)   // 1.0 * 2^0
        #expect(policy.delay(for: 1) == 2.0)   // 1.0 * 2^1
        #expect(policy.delay(for: 2) == 4.0)   // 1.0 * 2^2
        #expect(policy.delay(for: 3) == 8.0)   // 1.0 * 2^3
    }
    
    @Test("Fixed delay is constant")
    func testFixedDelay() {
        let policy = RetryPolicy.fixed(maxRetries: 5, delay: 3.0)
        
        #expect(policy.delay(for: 0) == 3.0)
        #expect(policy.delay(for: 1) == 3.0)
        #expect(policy.delay(for: 2) == 3.0)
        #expect(policy.delay(for: 10) == 3.0)
    }
    
    @Test("None policy delay is zero")
    func testNonePolicyDelay() {
        let policy = RetryPolicy.none
        #expect(policy.delay(for: 0) == 0)
    }
    
    @Test("shouldRetry for retryable errors")
    func testShouldRetryForRetryableErrors() {
        let policy = RetryPolicy.exponentialBackoff(maxRetries: 3, baseDelay: 1.0)
        
        #expect(policy.shouldRetry(for: URLError(.timedOut)) == true)
        #expect(policy.shouldRetry(for: URLError(.networkConnectionLost)) == true)
        #expect(policy.shouldRetry(for: URLError(.notConnectedToInternet)) == true)
        
        #expect(policy.shouldRetry(for: NetworkError.timeout) == true)
        #expect(policy.shouldRetry(for: NetworkError.noConnection) == true)
        #expect(policy.shouldRetry(for: NetworkError.serverError(statusCode: 500)) == true)
        #expect(policy.shouldRetry(for: NetworkError.serverError(statusCode: 503)) == true)
    }
    
    @Test("shouldRetry for non-retryable errors")
    func testShouldNotRetryForNonRetryableErrors() {
        let policy = RetryPolicy.exponentialBackoff(maxRetries: 3, baseDelay: 1.0)
        
        #expect(policy.shouldRetry(for: NetworkError.invalidURL) == false)
        #expect(policy.shouldRetry(for: NetworkError.unauthorized) == false)
        #expect(policy.shouldRetry(for: NetworkError.notFound) == false)
        #expect(policy.shouldRetry(for: NetworkError.serverError(statusCode: 400)) == false)
        #expect(policy.shouldRetry(for: NetworkError.serverError(statusCode: 404)) == false)
    }
    
    @Test("None policy never retries")
    func testNonePolicyNeverRetries() {
        let policy = RetryPolicy.none
        
        #expect(policy.shouldRetry(for: URLError(.timedOut)) == false)
        #expect(policy.shouldRetry(for: NetworkError.timeout) == false)
        #expect(policy.shouldRetry(for: NetworkError.serverError(statusCode: 500)) == false)
    }
    
    @Test("RetryPolicy is Equatable")
    func testRetryPolicyEquatable() {
        #expect(RetryPolicy.none == RetryPolicy.none)
        #expect(RetryPolicy.exponentialBackoff(maxRetries: 3, baseDelay: 1.0) == RetryPolicy.exponentialBackoff(maxRetries: 3, baseDelay: 1.0))
        #expect(RetryPolicy.fixed(maxRetries: 2, delay: 5.0) == RetryPolicy.fixed(maxRetries: 2, delay: 5.0))
        
        #expect(RetryPolicy.none != RetryPolicy.fixed(maxRetries: 1, delay: 1.0))
        #expect(RetryPolicy.exponentialBackoff(maxRetries: 3, baseDelay: 1.0) != RetryPolicy.exponentialBackoff(maxRetries: 5, baseDelay: 1.0))
    }
}
