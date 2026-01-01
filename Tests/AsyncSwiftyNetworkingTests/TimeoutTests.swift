import Testing
import Foundation
@testable import AsyncSwiftyNetworking

@Suite("Timeout Tests")
struct TimeoutTests {
    
    @Test("Endpoint timeout overrides configuration timeout")
    func testEndpointTimeoutOverride() async throws {
        // Given
        let mockSession = MockURLSession()
        // Configuration has 30s timeout
        let config = NetworkConfiguration(
            timeoutInterval: 30
        )
        
        let client = URLSessionNetworkClient(
            session: mockSession,
            configuration: config
        )
        
        mockSession.requestHandler = { request in
            return ("{}".data(using: .utf8)!, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        
        // When
        // Request with 60s timeout
        let _ : EmptyResponse = try await client.request(
            RequestBuilder.post("/test").timeout(60),
            baseUrl: "https://api.example.com"
        )
        
        // Then
        #expect(mockSession.capturedRequests.count == 1)
        #expect(mockSession.capturedRequests.first?.timeoutInterval == 60)
        #expect(mockSession.capturedRequests.first?.timeoutInterval != 30)
    }
    
    @Test("Default timeout used when endpoint timeout is nil")
    func testDefaultTimeout() async throws {
        // Given
        let mockSession = MockURLSession()
        let config = NetworkConfiguration(
            timeoutInterval: 45
        )
        
        let client = URLSessionNetworkClient(
            session: mockSession,
            configuration: config
        )
        
        mockSession.requestHandler = { request in
            return ("{}".data(using: .utf8)!, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        
        // When
        // Request without specific timeout
        let _ : EmptyResponse = try await client.request(
            RequestBuilder.get("/test"),
            baseUrl: "https://api.example.com"
        )
        
        // Then
        #expect(mockSession.capturedRequests.first?.timeoutInterval == 45)
    }
}
