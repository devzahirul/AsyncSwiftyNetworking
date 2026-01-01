import Testing
import Foundation
@testable import AsyncSwiftyNetworking

@Suite("Concurrent Request Tests")
struct ConcurrentRequestTests {
    
    @Test("Concurrent requests are handled independently")
    func testConcurrentRequests() async throws {
        let mockSession = MockURLSession()
        let requestCount = Check(0)
        
        mockSession.requestHandler = { request in
            await requestCount.increment()
            // Small delay to simulate network latency
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            
            // Extract ID from URL for verification
            let pathComponents = request.url?.pathComponents ?? []
            let id = pathComponents.last ?? "0"
            
            return ("""
                {"id": \(id), "name": "User \(id)", "email": "user\(id)@test.com"}
                """.data(using: .utf8)!,
                HTTPURLResponse(url: request.url!, 
                              statusCode: 200, 
                              httpVersion: nil, 
                              headerFields: nil)!)
        }
        
        let client = URLSessionNetworkClient(session: mockSession)
        
        async let result1: TestUserResponse = client.request(
            TestEndpoint.getUser(id: 1), 
            baseUrl: "https://test.com"
        )
        async let result2: TestUserResponse = client.request(
            TestEndpoint.getUser(id: 2), 
            baseUrl: "https://test.com"
        )
        async let result3: TestUserResponse = client.request(
            TestEndpoint.getUser(id: 3), 
            baseUrl: "https://test.com"
        )
        
        let (user1, user2, user3) = try await (result1, result2, result3)
        
        let finalCount = await requestCount.value
        #expect(finalCount == 3)
        #expect(user1.id == 1)
        #expect(user2.id == 2)
        #expect(user3.id == 3)
    }
}

// Thread-safe counter
actor Check {
    var value = 0
    init(_ value: Int) { self.value = value }
    func increment() { value += 1 }
}
