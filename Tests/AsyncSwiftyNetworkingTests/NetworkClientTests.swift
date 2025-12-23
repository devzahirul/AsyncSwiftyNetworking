import Testing
import Foundation
@testable import AsyncSwiftyNetworking

// MARK: - NetworkClient Tests

@Suite("URLSessionNetworkClient Tests")
struct NetworkClientTests {
    
    // MARK: - Successful Request Tests
    
    @Test("GET request returns decoded response")
    func testSuccessfulGETRequest() async throws {
        let mockSession = MockURLSession()
        let expectedUser = TestUserResponse(id: 1, name: "John Doe", email: "john@example.com", statusCode: nil)
        mockSession.mockSuccess(expectedUser)
        
        let client = URLSessionNetworkClient(session: mockSession)
        let result: TestUserResponse = try await client.request(
            TestEndpoint.getUser(id: 1),
            baseUrl: "https://api.test.com"
        )
        
        #expect(result.id == expectedUser.id)
        #expect(result.name == expectedUser.name)
        #expect(result.email == expectedUser.email)
        #expect(result.statusCode == 200)
        
        // Verify request was made correctly
        #expect(mockSession.capturedRequests.count == 1)
        let capturedRequest = mockSession.capturedRequests[0]
        #expect(capturedRequest.httpMethod == "GET")
        #expect(capturedRequest.url?.path == "/users/1")
    }
    
    @Test("POST request sends body correctly")
    func testSuccessfulPOSTRequest() async throws {
        let mockSession = MockURLSession()
        let createdUser = TestUserResponse(id: 2, name: "Jane Doe", email: "jane@example.com", statusCode: nil)
        mockSession.mockSuccess(createdUser, statusCode: 201)
        
        let client = URLSessionNetworkClient(session: mockSession)
        let result: TestUserResponse = try await client.request(
            TestEndpoint.createUser(name: "Jane Doe", email: "jane@example.com"),
            baseUrl: "https://api.test.com"
        )
        
        #expect(result.id == 2)
        #expect(result.statusCode == 201)
        
        let capturedRequest = mockSession.capturedRequests[0]
        #expect(capturedRequest.httpMethod == "POST")
        #expect(capturedRequest.httpBody != nil)
    }
    
    @Test("DELETE request uses correct method")
    func testSuccessfulDELETERequest() async throws {
        let mockSession = MockURLSession()
        mockSession.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return ("{}".data(using: .utf8)!, response)
        }
        
        let client = URLSessionNetworkClient(session: mockSession)
        let _: EmptyResponse = try await client.request(
            TestEndpoint.deleteUser(id: 1),
            baseUrl: "https://api.test.com"
        )
        
        let capturedRequest = mockSession.capturedRequests[0]
        #expect(capturedRequest.httpMethod == "DELETE")
        #expect(capturedRequest.url?.path == "/users/1")
    }
    
    // MARK: - Query Parameter Tests
    
    @Test("Query parameters are included in URL")
    func testQueryParameters() async throws {
        let mockSession = MockURLSession()
        mockSession.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return ("{\"id\": 1, \"name\": \"Test\"}".data(using: .utf8)!, response)
        }
        
        let client = URLSessionNetworkClient(session: mockSession)
        let _: TestUserResponse = try await client.request(
            TestEndpoint.searchUsers(query: "john"),
            baseUrl: "https://api.test.com"
        )
        
        let capturedRequest = mockSession.capturedRequests[0]
        let urlComponents = URLComponents(url: capturedRequest.url!, resolvingAgainstBaseURL: false)
        let queryItems = urlComponents?.queryItems ?? []
        
        #expect(queryItems.contains { $0.name == "q" && $0.value == "john" })
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Server error returns appropriate NetworkError")
    func testServerError() async throws {
        let mockSession = MockURLSession()
        mockSession.mockError(statusCode: 500, message: "Internal Server Error")
        
        let client = URLSessionNetworkClient(session: mockSession)
        
        await #expect(throws: NetworkError.self) {
            let _: TestUserResponse = try await client.request(
                TestEndpoint.getUser(id: 1),
                baseUrl: "https://api.test.com"
            )
        }
    }
    
    @Test("404 error returns notFound")
    func testNotFoundError() async throws {
        let mockSession = MockURLSession()
        mockSession.mockError(statusCode: 404)
        
        let client = URLSessionNetworkClient(session: mockSession)
        
        do {
            let _: TestUserResponse = try await client.request(
                TestEndpoint.getUser(id: 999),
                baseUrl: "https://api.test.com"
            )
            Issue.record("Expected error to be thrown")
        } catch let error as NetworkError {
            #expect(error == .notFound)
            #expect(error.isNotFound)
        }
    }
    
    @Test("401 error returns unauthorized")
    func testUnauthorizedError() async throws {
        let mockSession = MockURLSession()
        mockSession.mockError(statusCode: 401)
        
        let client = URLSessionNetworkClient(session: mockSession)
        
        do {
            let _: TestUserResponse = try await client.request(
                TestEndpoint.getUser(id: 1),
                baseUrl: "https://api.test.com"
            )
            Issue.record("Expected error to be thrown")
        } catch let error as NetworkError {
            #expect(error == .unauthorized)
        }
    }
    
    @Test("429 error returns rateLimited")
    func testRateLimitedError() async throws {
        let mockSession = MockURLSession()
        mockSession.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: "HTTP/1.1",
                headerFields: ["Retry-After": "60"]
            )!
            return ("{}".data(using: .utf8)!, response)
        }
        
        let client = URLSessionNetworkClient(session: mockSession)
        
        do {
            let _: TestUserResponse = try await client.request(
                TestEndpoint.getUser(id: 1),
                baseUrl: "https://api.test.com"
            )
            Issue.record("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .rateLimited(let retryAfter) = error {
                #expect(retryAfter == 60)
            } else {
                Issue.record("Expected rateLimited error")
            }
        }
    }
    
    @Test("Invalid URL throws error")
    func testInvalidURL() async throws {
        let mockSession = MockURLSession()
        let client = URLSessionNetworkClient(session: mockSession)
        
        // An empty base URL should result in an error (either invalidURL or underlying)
        await #expect(throws: NetworkError.self) {
            let _: TestUserResponse = try await client.request(
                TestEndpoint.getUser(id: 1),
                baseUrl: "" // Empty base URL
            )
        }
    }
    
    @Test("Network timeout throws timeout error")
    func testNetworkTimeout() async throws {
        let mockSession = MockURLSession()
        mockSession.mockNetworkFailure(URLError(.timedOut))
        
        let client = URLSessionNetworkClient(session: mockSession)
        
        do {
            let _: TestUserResponse = try await client.request(
                TestEndpoint.getUser(id: 1),
                baseUrl: "https://api.test.com"
            )
            Issue.record("Expected error to be thrown")
        } catch let error as NetworkError {
            #expect(error == .timeout)
        }
    }
    
    @Test("No connection throws noConnection error")
    func testNoConnection() async throws {
        let mockSession = MockURLSession()
        mockSession.mockNetworkFailure(URLError(.notConnectedToInternet))
        
        let client = URLSessionNetworkClient(session: mockSession)
        
        do {
            let _: TestUserResponse = try await client.request(
                TestEndpoint.getUser(id: 1),
                baseUrl: "https://api.test.com"
            )
            Issue.record("Expected error to be thrown")
        } catch let error as NetworkError {
            #expect(error == .noConnection)
        }
    }
    
    // MARK: - Interceptor Tests
    
    @Test("Request interceptors are applied in order")
    func testRequestInterceptors() async throws {
        let mockSession = MockURLSession()
        mockSession.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return ("{\"id\": 1, \"name\": \"Test\"}".data(using: .utf8)!, response)
        }
        
        let interceptor1 = MockRequestInterceptor()
        interceptor1.interceptHandler = { request in
            var modified = request
            modified.addValue("value1", forHTTPHeaderField: "X-Header-1")
            return modified
        }
        
        let interceptor2 = MockRequestInterceptor()
        interceptor2.interceptHandler = { request in
            var modified = request
            modified.addValue("value2", forHTTPHeaderField: "X-Header-2")
            return modified
        }
        
        let client = URLSessionNetworkClient(
            session: mockSession,
            requestInterceptors: [interceptor1, interceptor2]
        )
        
        let _: TestUserResponse = try await client.request(
            TestEndpoint.getUser(id: 1),
            baseUrl: "https://api.test.com"
        )
        
        let capturedRequest = mockSession.capturedRequests[0]
        #expect(capturedRequest.value(forHTTPHeaderField: "X-Header-1") == "value1")
        #expect(capturedRequest.value(forHTTPHeaderField: "X-Header-2") == "value2")
        
        #expect(interceptor1.interceptedRequests.count == 1)
        #expect(interceptor2.interceptedRequests.count == 1)
    }
    
    @Test("Response interceptors can modify data")
    func testResponseInterceptors() async throws {
        let mockSession = MockURLSession()
        mockSession.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return ("{\"id\": 1, \"name\": \"Original\"}".data(using: .utf8)!, response)
        }
        
        let responseInterceptor = MockResponseInterceptor()
        responseInterceptor.interceptHandler = { response, data in
            // Replace the response with different data
            return "{\"id\": 2, \"name\": \"Modified\"}".data(using: .utf8)!
        }
        
        let client = URLSessionNetworkClient(
            session: mockSession,
            responseInterceptors: [responseInterceptor]
        )
        
        let result: TestUserResponse = try await client.request(
            TestEndpoint.getUser(id: 1),
            baseUrl: "https://api.test.com"
        )
        
        #expect(result.id == 2)
        #expect(result.name == "Modified")
        #expect(responseInterceptor.interceptedResponses.count == 1)
    }
    
    // MARK: - Configuration Tests
    
    @Test("Configuration timeout is applied to request")
    func testConfigurationTimeout() async throws {
        let mockSession = MockURLSession()
        mockSession.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return ("{\"id\": 1, \"name\": \"Test\"}".data(using: .utf8)!, response)
        }
        
        let config = NetworkConfiguration(timeoutInterval: 15)
        let client = URLSessionNetworkClient(session: mockSession, configuration: config)
        
        let _: TestUserResponse = try await client.request(
            TestEndpoint.getUser(id: 1),
            baseUrl: "https://api.test.com"
        )
        
        let capturedRequest = mockSession.capturedRequests[0]
        #expect(capturedRequest.timeoutInterval == 15)
    }
    
    @Test("Configuration cache policy is applied")
    func testConfigurationCachePolicy() async throws {
        let mockSession = MockURLSession()
        mockSession.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return ("{\"id\": 1, \"name\": \"Test\"}".data(using: .utf8)!, response)
        }
        
        let config = NetworkConfiguration(cachePolicy: .returnCacheDataElseLoad)
        let client = URLSessionNetworkClient(session: mockSession, configuration: config)
        
        let _: TestUserResponse = try await client.request(
            TestEndpoint.getUser(id: 1),
            baseUrl: "https://api.test.com"
        )
        
        let capturedRequest = mockSession.capturedRequests[0]
        #expect(capturedRequest.cachePolicy == .returnCacheDataElseLoad)
    }
}
