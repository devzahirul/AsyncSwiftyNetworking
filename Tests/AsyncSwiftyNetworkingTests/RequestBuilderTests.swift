import XCTest
@testable import AsyncSwiftyNetworking

// MARK: - Request Builder Tests (TDD - RED Phase)

/// Tests for the fluent RequestBuilder API
/// These tests are written FIRST, before the implementation
final class RequestBuilderTests: XCTestCase {
    
    var mockSession: MockURLSession!
    var client: URLSessionNetworkClient!
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        client = URLSessionNetworkClient(session: mockSession)
    }
    
    // MARK: - Static Factory Methods
    
    func testGetRequestBuilder() throws {
        // Given
        let builder = RequestBuilder.get("/users/1")
        
        // Then
        XCTAssertEqual(builder.method, .get)
        XCTAssertEqual(builder.path, "/users/1")
    }
    
    func testPostRequestBuilder() throws {
        // Given
        let builder = RequestBuilder.post("/users")
        
        // Then
        XCTAssertEqual(builder.method, .post)
        XCTAssertEqual(builder.path, "/users")
    }
    
    func testPutRequestBuilder() throws {
        // Given
        let builder = RequestBuilder.put("/users/1")
        
        // Then
        XCTAssertEqual(builder.method, .put)
        XCTAssertEqual(builder.path, "/users/1")
    }
    
    func testDeleteRequestBuilder() throws {
        // Given
        let builder = RequestBuilder.delete("/users/1")
        
        // Then
        XCTAssertEqual(builder.method, .delete)
        XCTAssertEqual(builder.path, "/users/1")
    }
    
    func testPatchRequestBuilder() throws {
        // Given
        let builder = RequestBuilder.patch("/users/1")
        
        // Then
        XCTAssertEqual(builder.method, .patch)
        XCTAssertEqual(builder.path, "/users/1")
    }
    
    // MARK: - Fluent API Tests
    
    func testHeadersAreAdded() throws {
        // Given
        let builder = RequestBuilder.get("/users")
            .header("X-API-Key", "secret123")
            .header("X-Custom", "value")
        
        // Then
        XCTAssertEqual(builder.headers?["X-API-Key"], "secret123")
        XCTAssertEqual(builder.headers?["X-Custom"], "value")
    }
    
    func testQueryParametersAreAdded() throws {
        // Given
        let builder = RequestBuilder.get("/users")
            .query("page", "1")
            .query("limit", "20")
        
        // Then
        let queryItems = builder.queryItems ?? []
        XCTAssertTrue(queryItems.contains { $0.name == "page" && $0.value == "1" })
        XCTAssertTrue(queryItems.contains { $0.name == "limit" && $0.value == "20" })
    }
    
    func testCodableBodyIsEncoded() throws {
        // Given
        struct CreateUser: Codable {
            let name: String
            let email: String
        }
        let user = CreateUser(name: "John", email: "john@example.com")
        
        // When
        let builder = RequestBuilder.post("/users")
            .body(user)
        
        // Then
        XCTAssertNotNil(builder.body)
        
        // Verify JSON content
        let decoded = try JSONDecoder().decode(CreateUser.self, from: builder.body!)
        XCTAssertEqual(decoded.name, "John")
        XCTAssertEqual(decoded.email, "john@example.com")
    }
    
    func testRawDataBody() throws {
        // Given
        let rawData = "raw content".data(using: .utf8)!
        
        // When
        let builder = RequestBuilder.post("/upload")
            .body(rawData)
        
        // Then
        XCTAssertEqual(builder.body, rawData)
    }
    
    func testTimeoutIsSet() throws {
        // Given
        let builder = RequestBuilder.get("/users")
            .timeout(60)
        
        // Then
        XCTAssertEqual(builder.timeoutInterval, 60)
    }
    
    // MARK: - Endpoint Conformance
    
    func testConformsToEndpoint() throws {
        // Given
        let builder = RequestBuilder.post("/users")
            .header("Authorization", "Bearer token")
            .query("source", "app")
            .timeout(30)
        
        // Then - RequestBuilder should conform to Endpoint
        let endpoint: Endpoint = builder
        
        XCTAssertEqual(endpoint.path, "/users")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNotNil(endpoint.headers)
        XCTAssertNotNil(endpoint.queryItems)
    }
    
    // MARK: - Integration with NetworkClient
    
    func testRequestBuilderWithClient() async throws {
        // Given
        mockSession.requestHandler = { request in
            // Verify the request was built correctly
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.path.contains("/users") == true)
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "secret")
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return ("{\"id\": 1, \"name\": \"John\", \"email\": \"john@test.com\"}".data(using: .utf8)!, response)
        }
        
        // When
        let result: TestUserResponse = try await client.request(
            RequestBuilder.post("/users")
                .header("X-API-Key", "secret")
                .body(["name": "John", "email": "john@test.com"]),
            baseUrl: "https://api.test.com"
        )
        
        // Then
        XCTAssertEqual(result.id, 1)
        XCTAssertEqual(result.name, "John")
    }
    
    // MARK: - Chaining Tests
    
    func testFullChainedRequest() throws {
        // Given
        struct UserPayload: Codable {
            let name: String
        }
        
        // When
        let builder = RequestBuilder.post("/users")
            .header("Authorization", "Bearer token")
            .header("Accept", "application/json")
            .query("source", "mobile")
            .query("version", "2")
            .body(UserPayload(name: "Test"))
            .timeout(45)
        
        // Then - all properties should be set correctly
        XCTAssertEqual(builder.method, .post)
        XCTAssertEqual(builder.path, "/users")
        XCTAssertEqual(builder.headers?["Authorization"], "Bearer token")
        XCTAssertEqual(builder.headers?["Accept"], "application/json")
        XCTAssertEqual(builder.queryItems?.count, 2)
        XCTAssertNotNil(builder.body)
        XCTAssertEqual(builder.timeoutInterval, 45)
    }
}
