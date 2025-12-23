import XCTest
@testable import AsyncSwiftyNetworking

// MARK: - Convenience Factory Tests (TDD - RED Phase)

/// Tests for convenience factory methods on URLSessionNetworkClient
/// These tests are written FIRST, before the implementation
final class ConvenienceFactoryTests: XCTestCase {
    
    // MARK: - Quick Setup Tests
    
    func testQuickSetupCreatesClient() throws {
        // When
        let client = URLSessionNetworkClient.quick(baseURL: "https://api.example.com")
        
        // Then
        XCTAssertNotNil(client)
        XCTAssertEqual(client.baseURL, "https://api.example.com")
    }
    
    func testQuickSetupWithLogging() throws {
        // When
        let client = URLSessionNetworkClient.quick(
            baseURL: "https://api.example.com",
            logging: true
        )
        
        // Then
        XCTAssertNotNil(client)
        XCTAssertTrue(client.hasLoggingInterceptor)
    }
    
    func testQuickSetupWithoutLogging() throws {
        // When
        let client = URLSessionNetworkClient.quick(
            baseURL: "https://api.example.com",
            logging: false
        )
        
        // Then
        XCTAssertFalse(client.hasLoggingInterceptor)
    }
    
    // MARK: - Auth Setup Tests
    
    func testWithAuthSetupCreatesClient() throws {
        // Given
        let mockStorage = MockTokenStorage()
        let mockHandler = MockTokenRefreshHandler()
        
        // When
        let client = URLSessionNetworkClient.withAuth(
            baseURL: "https://api.example.com",
            tokenStorage: mockStorage,
            refreshHandler: mockHandler
        )
        
        // Then
        XCTAssertNotNil(client)
        XCTAssertTrue(client.hasAuthInterceptor)
        XCTAssertTrue(client.hasRefreshInterceptor)
    }
    
    // MARK: - BaseURL Convenience Tests
    
    func testRequestWithoutBaseURLUsesConfigured() async throws {
        // Given
        let mockSession = MockURLSession()
        mockSession.requestHandler = { request in
            // Verify the URL uses the configured baseURL
            XCTAssertTrue(request.url?.absoluteString.starts(with: "https://api.example.com") == true)
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return ("{\"id\": 1, \"name\": \"Test\", \"email\": \"test@test.com\"}".data(using: .utf8)!, response)
        }
        
        let client = URLSessionNetworkClient.quick(
            baseURL: "https://api.example.com",
            session: mockSession
        )
        
        // When - using request without baseUrl parameter
        let result: TestUserResponse = try await client.request(TestEndpoint.getUser(id: 1))
        
        // Then
        XCTAssertEqual(result.id, 1)
    }
    
    // Note: requestData and requestVoid tests skipped for now
    // They require passing raw data through the decode pipeline
    // which needs a different architecture approach
    
    // MARK: - Mobile Configuration Preset
    
    func testMobilePreset() throws {
        // When
        let client = URLSessionNetworkClient.mobile(baseURL: "https://api.example.com")
        
        // Then
        XCTAssertNotNil(client)
        // Mobile preset should have retry policy and longer timeout
    }
}

// Note: MockTokenStorage and MockTokenRefreshHandler are defined in Mocks/Mocks.swift

