import Testing
import Foundation
@testable import AsyncSwiftyNetworking

@Suite("NetworkResult Tests")
struct NetworkResultTests {
    
    @Test("Captures metadata correctly")
    func testCapturesMetadata() async throws {
        // Given
        let mockSession = MockURLSession()
        let client = URLSessionNetworkClient(
            session: mockSession,
            configuration: .default,
            baseURL: "https://api.example.com",
            hasLoggingInterceptor: false,
            hasAuthInterceptor: false,
            hasRefreshInterceptor: false
        )
        
        let user = TestUserResponse(id: 1, name: "Test", email: nil, statusCode: nil)
        
        // Configure mock session
        mockSession.mockSuccess(
            user, 
            statusCode: 200, 
            headers: ["X-Custom": "Value"]
        )
        
        // When
        let result: NetworkResult<TestUserResponse> = try await client.requestWithMetadata(
            RequestBuilder.get("/users/1"), 
            baseUrl: "https://api.example.com"
        )
        
        // Then
        #expect(result.statusCode == 200)
        #expect(result.url?.absoluteString == "https://api.example.com/users/1")
        #expect(result.headers["X-Custom"] == "Value")
        #expect(result.duration >= 0)
        #expect(result.data.id == 1)
        #expect(result.data.name == "Test")
    }
}
