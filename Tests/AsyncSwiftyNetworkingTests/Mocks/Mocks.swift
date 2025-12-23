import Foundation
@testable import AsyncSwiftyNetworking

// MARK: - Mock URLSession

/// A mock implementation of URLSessionProtocol for testing.
/// Allows capturing requests and returning configurable responses.
final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    
    /// Handler that processes requests and returns responses.
    var requestHandler: ((URLRequest) async throws -> (Data, URLResponse))?
    
    /// All requests that have been made through this session.
    private(set) var capturedRequests: [URLRequest] = []
    
    /// Reset the captured state for a new test.
    func reset() {
        capturedRequests = []
        requestHandler = nil
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequests.append(request)
        
        guard let handler = requestHandler else {
            throw NSError(domain: "MockURLSession", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No request handler configured"
            ])
        }
        
        return try await handler(request)
    }
    
    // MARK: - Convenience Response Builders
    
    /// Configures the mock to return a successful JSON response.
    func mockSuccess<T: Encodable>(
        _ value: T,
        statusCode: Int = 200,
        headers: [String: String]? = nil
    ) {
        requestHandler = { request in
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data = try encoder.encode(value)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            )!
            return (data, response)
        }
    }
    
    /// Configures the mock to return an error response.
    func mockError(
        statusCode: Int,
        message: String? = nil,
        headers: [String: String]? = nil
    ) {
        requestHandler = { request in
            var errorBody: [String: Any] = [:]
            if let message = message {
                errorBody["message"] = message
            }
            let data = try JSONSerialization.data(withJSONObject: errorBody)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            )!
            return (data, response)
        }
    }
    
    /// Configures the mock to throw an error (simulating network failures).
    func mockNetworkFailure(_ error: Error) {
        requestHandler = { _ in
            throw error
        }
    }
    
    /// Configures the mock to return empty data with a status code.
    func mockEmptyResponse(statusCode: Int = 200) {
        requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (Data(), response)
        }
    }
}

// MARK: - Mock Token Storage

/// A mock implementation of TokenStorage for testing.
final class MockTokenStorage: TokenStorage, @unchecked Sendable {
    
    var mockToken: String?
    private(set) var savedTokens: [String] = []
    private(set) var clearCallCount = 0
    
    var currentToken: String? {
        return mockToken
    }
    
    @discardableResult
    func save(_ token: String) -> Bool {
        mockToken = token
        savedTokens.append(token)
        return true
    }
    
    func clear() {
        mockToken = nil
        clearCallCount += 1
    }
    
    func reset() {
        mockToken = nil
        savedTokens = []
        clearCallCount = 0
    }
}

// MARK: - Mock Request Interceptor

/// A mock request interceptor for testing the interceptor chain.
final class MockRequestInterceptor: RequestInterceptor {
    
    var interceptHandler: ((URLRequest) async throws -> URLRequest)?
    private(set) var interceptedRequests: [URLRequest] = []
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        interceptedRequests.append(request)
        
        if let handler = interceptHandler {
            return try await handler(request)
        }
        
        return request
    }
    
    func reset() {
        interceptedRequests = []
        interceptHandler = nil
    }
}

// MARK: - Mock Response Interceptor

/// A mock response interceptor for testing the interceptor chain.
final class MockResponseInterceptor: ResponseInterceptor {
    
    var interceptHandler: ((HTTPURLResponse, Data) async throws -> Data)?
    private(set) var interceptedResponses: [(HTTPURLResponse, Data)] = []
    
    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        interceptedResponses.append((response, data))
        
        if let handler = interceptHandler {
            return try await handler(response, data)
        }
        
        return data
    }
    
    func reset() {
        interceptedResponses = []
        interceptHandler = nil
    }
}

// MARK: - Test Endpoint

/// A test endpoint implementation for testing.
enum TestEndpoint: Endpoint {
    case getUser(id: Int)
    case getUsers
    case createUser(name: String, email: String)
    case updateUser(id: Int, name: String)
    case deleteUser(id: Int)
    case searchUsers(query: String)
    
    var path: String {
        switch self {
        case .getUser(let id):
            return "/users/\(id)"
        case .getUsers:
            return "/users"
        case .createUser:
            return "/users"
        case .updateUser(let id, _):
            return "/users/\(id)"
        case .deleteUser(let id):
            return "/users/\(id)"
        case .searchUsers:
            return "/users/search"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getUser, .getUsers, .searchUsers:
            return .get
        case .createUser:
            return .post
        case .updateUser:
            return .put
        case .deleteUser:
            return .delete
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .searchUsers(let query):
            return [URLQueryItem(name: "q", value: query)]
        default:
            return nil
        }
    }
    
    var body: Data? {
        switch self {
        case .createUser(let name, let email):
            let body = ["name": name, "email": email]
            return try? JSONEncoder().encode(body)
        case .updateUser(_, let name):
            let body = ["name": name]
            return try? JSONEncoder().encode(body)
        default:
            return nil
        }
    }
}

// MARK: - Test Response Models

/// A test response model for testing.
struct TestUserResponse: HTTPResponseDecodable, Equatable, Codable {
    let id: Int
    let name: String
    let email: String?
    var statusCode: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email
    }
}

/// A simple empty response for testing.
struct EmptyResponse: HTTPResponseDecodable, Equatable {
    var statusCode: Int?
}

// MARK: - Mock Token Refresh Handler

/// A mock implementation of TokenRefreshHandler for testing.
final class MockTokenRefreshHandler: TokenRefreshHandler, @unchecked Sendable {
    
    private(set) var refreshCallCount = 0
    private(set) var failureErrors: [Error] = []
    
    var mockNewToken: String = "new-mock-token"
    var shouldFail: Bool = false
    var failureError: Error = NetworkError.unknown
    
    func refreshToken() async throws -> String {
        refreshCallCount += 1
        
        if shouldFail {
            throw failureError
        }
        
        return mockNewToken
    }
    
    func onRefreshFailure(_ error: Error) async {
        failureErrors.append(error)
    }
    
    func reset() {
        refreshCallCount = 0
        failureErrors = []
        mockNewToken = "new-mock-token"
        shouldFail = false
        failureError = NetworkError.unknown
    }
}

