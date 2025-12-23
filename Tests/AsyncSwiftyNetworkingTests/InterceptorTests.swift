import Testing
import Foundation
@testable import AsyncSwiftyNetworking

// MARK: - Interceptor Tests

@Suite("Interceptor Tests")
struct InterceptorTests {
    
    // MARK: - AuthInterceptor Tests
    
    @Test("AuthInterceptor adds Bearer token when token exists")
    func testAuthInterceptorWithToken() async throws {
        let mockStorage = MockTokenStorage()
        mockStorage.mockToken = "test-token-123"
        
        let interceptor = AuthInterceptor(storage: mockStorage)
        var request = URLRequest(url: URL(string: "https://api.test.com/users")!)
        
        request = try await interceptor.intercept(request)
        
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token-123")
    }
    
    @Test("AuthInterceptor does not add header when no token")
    func testAuthInterceptorWithoutToken() async throws {
        let mockStorage = MockTokenStorage()
        mockStorage.mockToken = nil
        
        let interceptor = AuthInterceptor(storage: mockStorage)
        var request = URLRequest(url: URL(string: "https://api.test.com/users")!)
        
        request = try await interceptor.intercept(request)
        
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }
    
    @Test("AuthInterceptor preserves existing headers")
    func testAuthInterceptorPreservesHeaders() async throws {
        let mockStorage = MockTokenStorage()
        mockStorage.mockToken = "token"
        
        let interceptor = AuthInterceptor(storage: mockStorage)
        var request = URLRequest(url: URL(string: "https://api.test.com/users")!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request = try await interceptor.intercept(request)
        
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token")
    }
    
    // MARK: - LoggingInterceptor Tests
    
    @Test("LoggingInterceptor with none level passes request unchanged")
    func testLoggingInterceptorNoneLevel() async throws {
        let interceptor = LoggingInterceptor(level: .none)
        let originalRequest = URLRequest(url: URL(string: "https://api.test.com")!)
        
        let result = try await interceptor.intercept(originalRequest)
        
        #expect(result.url == originalRequest.url)
    }
    
    @Test("LoggingInterceptor with basic level passes request unchanged")
    func testLoggingInterceptorBasicLevel() async throws {
        let interceptor = LoggingInterceptor(level: .basic)
        let originalRequest = URLRequest(url: URL(string: "https://api.test.com")!)
        
        let result = try await interceptor.intercept(originalRequest)
        
        #expect(result.url == originalRequest.url)
    }
    
    @Test("LoggingInterceptor with verbose level passes request unchanged")
    func testLoggingInterceptorVerboseLevel() async throws {
        let interceptor = LoggingInterceptor(level: .verbose)
        var originalRequest = URLRequest(url: URL(string: "https://api.test.com")!)
        originalRequest.httpMethod = "POST"
        originalRequest.httpBody = "test".data(using: .utf8)
        
        let result = try await interceptor.intercept(originalRequest)
        
        #expect(result.url == originalRequest.url)
        #expect(result.httpMethod == originalRequest.httpMethod)
    }
    
    @Test("LoggingInterceptor response interceptor passes data unchanged")
    func testLoggingInterceptorResponseInterceptor() async throws {
        let interceptor = LoggingInterceptor(level: .verbose)
        let response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        let originalData = "test data".data(using: .utf8)!
        
        let result = try await interceptor.intercept(response, data: originalData)
        
        #expect(result == originalData)
    }
    
    // MARK: - Mock Interceptor Tests
    
    @Test("Mock interceptors capture requests and responses")
    func testMockInterceptorCapture() async throws {
        let requestInterceptor = MockRequestInterceptor()
        let responseInterceptor = MockResponseInterceptor()
        
        let request = URLRequest(url: URL(string: "https://api.test.com")!)
        _ = try await requestInterceptor.intercept(request)
        
        let response = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        let data = "test".data(using: .utf8)!
        _ = try await responseInterceptor.intercept(response, data: data)
        
        #expect(requestInterceptor.interceptedRequests.count == 1)
        #expect(responseInterceptor.interceptedResponses.count == 1)
    }
    
    @Test("Mock interceptor can modify requests")
    func testMockInterceptorModification() async throws {
        let interceptor = MockRequestInterceptor()
        interceptor.interceptHandler = { request in
            var modified = request
            modified.setValue("custom-value", forHTTPHeaderField: "X-Custom")
            return modified
        }
        
        var request = URLRequest(url: URL(string: "https://api.test.com")!)
        request = try await interceptor.intercept(request)
        
        #expect(request.value(forHTTPHeaderField: "X-Custom") == "custom-value")
    }
    
    @Test("Mock interceptor can throw errors")
    func testMockInterceptorThrowsError() async throws {
        let interceptor = MockRequestInterceptor()
        interceptor.interceptHandler = { _ in
            throw NetworkError.unauthorized
        }
        
        let request = URLRequest(url: URL(string: "https://api.test.com")!)
        
        await #expect(throws: NetworkError.self) {
            _ = try await interceptor.intercept(request)
        }
    }
    
    @Test("Mock interceptor reset clears state")
    func testMockInterceptorReset() async throws {
        let interceptor = MockRequestInterceptor()
        let request = URLRequest(url: URL(string: "https://api.test.com")!)
        _ = try await interceptor.intercept(request)
        
        #expect(interceptor.interceptedRequests.count == 1)
        
        interceptor.reset()
        
        #expect(interceptor.interceptedRequests.count == 0)
        #expect(interceptor.interceptHandler == nil)
    }
}
