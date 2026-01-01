import Foundation

/// A result wrapper that includes response metadata alongside the decoded data
public struct NetworkResult<T: HTTPResponseDecodable>: Sendable where T: Sendable {
    /// The decoded response data
    public let data: T
    
    /// HTTP status code
    public let statusCode: Int
    
    /// Response headers
    public let headers: [String: String]
    
    /// Response URL (after redirects)
    public let url: URL?
    
    /// Duration of the request in seconds
    public let duration: TimeInterval
    
    public init(
        data: T,
        statusCode: Int,
        headers: [String: String],
        url: URL?,
        duration: TimeInterval
    ) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
        self.url = url
        self.duration = duration
    }
}

// MARK: - NetworkClient Result Extensions

public extension NetworkClient {
    /// Performs a request and returns a rich result with metadata
    /// - Parameters:
    ///   - endpoint: The endpoint to request
    ///   - baseUrl: The base URL for the API
    /// - Returns: A `NetworkResult` containing data and metadata
    func requestWithMetadata<T: HTTPResponseDecodable>(
        _ endpoint: Endpoint,
        baseUrl: String
    ) async throws -> NetworkResult<T> {
        // Default implementation throws
        throw NetworkError.underlying("Not implemented for this client type")
    }
}
