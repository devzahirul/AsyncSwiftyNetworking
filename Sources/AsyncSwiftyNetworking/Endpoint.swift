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
    
    /// Optional timeout override for this specific endpoint
    var timeoutInterval: TimeInterval? { get }
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
    
    var timeoutInterval: TimeInterval? {
        return nil
    }
    
    // MARK: - Logging Configuration
    
    /// Whether this endpoint should be logged. Default is true.
    /// Set to false for sensitive endpoints (login, payment, etc.)
    var loggingEnabled: Bool {
        return true
    }
    
    /// The log level for this endpoint. Default is .verbose.
    /// Only applies if loggingEnabled is true.
    var logLevel: LogLevel {
        return .verbose
    }
}

// MARK: - LogLevel

/// Log level options for controlling per-endpoint verbosity.
public enum LogLevel: Int, Sendable, Comparable {
    case none = 0
    case basic = 1
    case verbose = 2
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
