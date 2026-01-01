import Foundation

// MARK: - Request Builder

/// A fluent builder for creating API requests without defining a full Endpoint enum.
/// Perfect for one-off requests or rapid prototyping.
///
/// Usage:
/// ```swift
/// let user: User = try await client.request(
///     RequestBuilder.post("/users")
///         .header("X-API-Key", apiKey)
///         .body(CreateUserRequest(name: "John"))
/// )
/// ```
public struct RequestBuilder: Endpoint, Sendable {
    
    // MARK: - Properties
    
    public let path: String
    public let method: HTTPMethod
    public private(set) var headers: [String: String]?
    public private(set) var queryItems: [URLQueryItem]?
    public private(set) var body: Data?
    
    /// Custom timeout for this request (optional)
    public private(set) var timeoutInterval: TimeInterval?
    
    /// Custom encoder for body encoding
    private let encoder: JSONEncoder
    
    // MARK: - Static Factory Methods
    
    /// Creates a GET request builder
    public static func get(_ path: String) -> RequestBuilder {
        RequestBuilder(path: path, method: .get)
    }
    
    /// Creates a POST request builder
    public static func post(_ path: String) -> RequestBuilder {
        RequestBuilder(path: path, method: .post)
    }
    
    /// Creates a PUT request builder
    public static func put(_ path: String) -> RequestBuilder {
        RequestBuilder(path: path, method: .put)
    }
    
    /// Creates a DELETE request builder
    public static func delete(_ path: String) -> RequestBuilder {
        RequestBuilder(path: path, method: .delete)
    }
    
    /// Creates a PATCH request builder
    public static func patch(_ path: String) -> RequestBuilder {
        RequestBuilder(path: path, method: .patch)
    }
    
    // MARK: - Initialization
    
    private init(
        path: String,
        method: HTTPMethod,
        headers: [String: String]? = ["Content-Type": "application/json", "Accept": "application/json"],
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil,
        timeoutInterval: TimeInterval? = nil,
        encoder: JSONEncoder = URLSessionNetworkClient.defaultEncoder
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.timeoutInterval = timeoutInterval
        self.encoder = encoder
    }
    
    // MARK: - Fluent API
    
    /// Adds a header to the request
    /// - Parameters:
    ///   - key: The header name
    ///   - value: The header value
    /// - Returns: A new builder with the header added
    public func header(_ key: String, _ value: String) -> RequestBuilder {
        var newHeaders = headers ?? [:]
        newHeaders[key] = value
        return RequestBuilder(
            path: path,
            method: method,
            headers: newHeaders,
            queryItems: queryItems,
            body: body,
            timeoutInterval: timeoutInterval,
            encoder: encoder
        )
    }
    
    /// Adds multiple headers to the request
    /// - Parameter headers: Dictionary of headers to add
    /// - Returns: A new builder with the headers added
    public func headers(_ headers: [String: String]) -> RequestBuilder {
        var newHeaders = self.headers ?? [:]
        for (key, value) in headers {
            newHeaders[key] = value
        }
        return RequestBuilder(
            path: path,
            method: method,
            headers: newHeaders,
            queryItems: queryItems,
            body: body,
            timeoutInterval: timeoutInterval,
            encoder: encoder
        )
    }
    
    /// Adds a query parameter to the request
    /// - Parameters:
    ///   - key: The query parameter name
    ///   - value: The query parameter value
    /// - Returns: A new builder with the query parameter added
    public func query(_ key: String, _ value: String) -> RequestBuilder {
        var newQueryItems = queryItems ?? []
        newQueryItems.append(URLQueryItem(name: key, value: value))
        return RequestBuilder(
            path: path,
            method: method,
            headers: headers,
            queryItems: newQueryItems,
            body: body,
            timeoutInterval: timeoutInterval,
            encoder: encoder
        )
    }
    
    /// Adds multiple query parameters to the request
    /// - Parameter parameters: Dictionary of query parameters to add
    /// - Returns: A new builder with the query parameters added
    public func queryItems(_ parameters: [String: String]) -> RequestBuilder {
        var newQueryItems = queryItems ?? []
        for (key, value) in parameters {
            newQueryItems.append(URLQueryItem(name: key, value: value))
        }
        return RequestBuilder(
            path: path,
            method: method,
            headers: headers,
            queryItems: newQueryItems,
            body: body,
            timeoutInterval: timeoutInterval,
            encoder: encoder
        )
    }
    
    /// Sets the request body from a Codable value
    /// - Parameter value: The value to encode as JSON
    /// - Returns: A new builder with the body set
    public func body<T: Encodable>(_ value: T) -> RequestBuilder {
        let encodedBody = try? encoder.encode(value)
        return RequestBuilder(
            path: path,
            method: method,
            headers: headers,
            queryItems: queryItems,
            body: encodedBody,
            timeoutInterval: timeoutInterval,
            encoder: encoder
        )
    }
    
    /// Sets the request body from raw Data
    /// - Parameter data: The raw data to send
    /// - Returns: A new builder with the body set
    public func body(_ data: Data) -> RequestBuilder {
        return RequestBuilder(
            path: path,
            method: method,
            headers: headers,
            queryItems: queryItems,
            body: data,
            timeoutInterval: timeoutInterval,
            encoder: encoder
        )
    }
    
    /// Sets a custom timeout for this request
    /// - Parameter seconds: The timeout in seconds
    /// - Returns: A new builder with the timeout set
    public func timeout(_ seconds: TimeInterval) -> RequestBuilder {
        return RequestBuilder(
            path: path,
            method: method,
            headers: headers,
            queryItems: queryItems,
            body: body,
            timeoutInterval: seconds,
            encoder: encoder
        )
    }
    
    /// Sets a custom JSON encoder for body encoding
    /// - Parameter encoder: The encoder to use
    /// - Returns: A new builder with the encoder set
    public func encoder(_ encoder: JSONEncoder) -> RequestBuilder {
        return RequestBuilder(
            path: path,
            method: method,
            headers: headers,
            queryItems: queryItems,
            body: body,
            timeoutInterval: timeoutInterval,
            encoder: encoder
        )
    }
    
    // MARK: - Convenience Methods
    
    /// Creates a builder with authorization header
    /// - Parameters:
    ///   - token: The access token
    ///   - scheme: The auth scheme (default: Bearer)
    /// - Returns: A new builder with the header added
    public func authorize(_ token: String, scheme: String = "Bearer") -> RequestBuilder {
        header("Authorization", "\(scheme) \(token)")
    }
    
    /// Sets Content-Type to application/x-www-form-urlencoded
    /// - Returns: A new builder with appropriate header
    public func formURLEncoded() -> RequestBuilder {
        header("Content-Type", "application/x-www-form-urlencoded")
    }
    
    /// Adds If-None-Match header for conditional requests
    /// - Parameter etag: The ETag to check against
    /// - Returns: A new builder with the header added
    public func ifNoneMatch(_ etag: String) -> RequestBuilder {
        header("If-None-Match", etag)
    }
    
    /// Sets Accept-Language header
    /// - Parameter language: The language string (e.g., "en-US")
    /// - Returns: A new builder with the header added
    public func acceptLanguage(_ language: String) -> RequestBuilder {
        header("Accept-Language", language)
    }
}
