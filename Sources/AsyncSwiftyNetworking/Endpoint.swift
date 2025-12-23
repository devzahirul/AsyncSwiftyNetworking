import Foundation

/// HTTP Methods supported by the networking library.
/// Conforms to `Sendable` for safe concurrent access.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// A protocol that defines a single API endpoint.
public protocol Endpoint {
    /// The path for the endpoint (e.g. "/users").
    var path: String { get }
    
    /// The HTTP method for the endpoint.
    var method: HTTPMethod { get }
    
    /// The headers for the request.
    var headers: [String: String]? { get }
    
    /// The query items for the request.
    var queryItems: [URLQueryItem]? { get }
    
    /// The body for the request.
    var body: Data? { get }
}

/// Default extensions for commonly used functionality
public extension Endpoint {
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
    
    var body: Data? {
        return nil
    }
}
