import Testing
import Foundation
@testable import AsyncSwiftyNetworking

// MARK: - Endpoint Tests

@Suite("Endpoint Protocol Tests")
struct EndpointTests {
    
    // MARK: - Default Values Tests
    
    @Test("Default headers include JSON content types")
    func testDefaultHeaders() {
        let endpoint = TestEndpoint.getUsers
        
        #expect(endpoint.headers?["Content-Type"] == "application/json")
        #expect(endpoint.headers?["Accept"] == "application/json")
    }
    
    @Test("Default queryItems is nil")
    func testDefaultQueryItems() {
        let endpoint = TestEndpoint.getUser(id: 1)
        // getUser doesn't override queryItems, so it uses the default
        #expect(endpoint.queryItems == nil)
    }
    
    @Test("Default body is nil for GET requests")
    func testDefaultBodyForGET() {
        let endpoint = TestEndpoint.getUsers
        #expect(endpoint.body == nil)
    }
    
    // MARK: - Path Tests
    
    @Test("Path is correctly formed for different endpoints")
    func testPaths() {
        #expect(TestEndpoint.getUser(id: 42).path == "/users/42")
        #expect(TestEndpoint.getUsers.path == "/users")
        #expect(TestEndpoint.createUser(name: "Test", email: "test@test.com").path == "/users")
        #expect(TestEndpoint.updateUser(id: 5, name: "Updated").path == "/users/5")
        #expect(TestEndpoint.deleteUser(id: 10).path == "/users/10")
        #expect(TestEndpoint.searchUsers(query: "test").path == "/users/search")
    }
    
    // MARK: - Method Tests
    
    @Test("HTTP methods are correctly assigned")
    func testHTTPMethods() {
        #expect(TestEndpoint.getUser(id: 1).method == .get)
        #expect(TestEndpoint.getUsers.method == .get)
        #expect(TestEndpoint.createUser(name: "a", email: "b").method == .post)
        #expect(TestEndpoint.updateUser(id: 1, name: "a").method == .put)
        #expect(TestEndpoint.deleteUser(id: 1).method == .delete)
        #expect(TestEndpoint.searchUsers(query: "x").method == .get)
    }
    
    // MARK: - HTTPMethod Raw Values
    
    @Test("HTTPMethod raw values are correct")
    func testHTTPMethodRawValues() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
        #expect(HTTPMethod.patch.rawValue == "PATCH")
    }
    
    // MARK: - Query Items Tests
    
    @Test("Query items are correctly set")
    func testQueryItems() {
        let endpoint = TestEndpoint.searchUsers(query: "john doe")
        let queryItems = endpoint.queryItems ?? []
        
        #expect(queryItems.count == 1)
        #expect(queryItems[0].name == "q")
        #expect(queryItems[0].value == "john doe")
    }
    
    // MARK: - Body Tests
    
    @Test("POST body is correctly encoded")
    func testPOSTBody() throws {
        let endpoint = TestEndpoint.createUser(name: "John", email: "john@test.com")
        let bodyData = endpoint.body
        
        #expect(bodyData != nil)
        
        let decoded = try JSONDecoder().decode([String: String].self, from: bodyData!)
        #expect(decoded["name"] == "John")
        #expect(decoded["email"] == "john@test.com")
    }
    
    @Test("PUT body is correctly encoded")
    func testPUTBody() throws {
        let endpoint = TestEndpoint.updateUser(id: 1, name: "Updated Name")
        let bodyData = endpoint.body
        
        #expect(bodyData != nil)
        
        let decoded = try JSONDecoder().decode([String: String].self, from: bodyData!)
        #expect(decoded["name"] == "Updated Name")
    }
}

// MARK: - Pagination Tests

@Suite("Pagination Tests")
struct PaginationTests {
    
    @Test("Default pagination values")
    func testDefaultValues() {
        let params = PaginationParams()
        #expect(params.page == 1)
        #expect(params.pageSize == 20)
    }
    
    @Test("Custom pagination values")
    func testCustomValues() {
        let params = PaginationParams(page: 5, pageSize: 50)
        #expect(params.page == 5)
        #expect(params.pageSize == 50)
    }
    
    @Test("Query items are correctly generated")
    func testQueryItems() {
        let params = PaginationParams(page: 3, pageSize: 25)
        let queryItems = params.queryItems
        
        #expect(queryItems.count == 2)
        #expect(queryItems.contains { $0.name == "page" && $0.value == "3" })
        #expect(queryItems.contains { $0.name == "per_page" && $0.value == "25" })
    }
    
    @Test("PaginatedResponse hasNextPage calculation")
    func testHasNextPage() {
        // Has next page
        let response1 = PaginatedResponse<TestUserResponse>(
            data: [],
            page: 1,
            totalPages: 5,
            totalItems: 100,
            statusCode: 200
        )
        #expect(response1.hasNextPage == true)
        
        // On last page
        let response2 = PaginatedResponse<TestUserResponse>(
            data: [],
            page: 5,
            totalPages: 5,
            totalItems: 100,
            statusCode: 200
        )
        #expect(response2.hasNextPage == false)
        
        // Single page
        let response3 = PaginatedResponse<TestUserResponse>(
            data: [],
            page: 1,
            totalPages: 1,
            totalItems: 5,
            statusCode: 200
        )
        #expect(response3.hasNextPage == false)
    }
}
