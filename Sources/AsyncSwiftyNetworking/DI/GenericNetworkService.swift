import Foundation

/// Generic Network Service that works with any HTTPResponseDecodable type
/// User only needs to provide the endpoint
public final class GenericNetworkService<T: HTTPResponseDecodable>: @unchecked Sendable {
    
    private let endpoint: RequestBuilder
    private var client: URLSessionNetworkClient?
    
    /// Initialize with an endpoint
    /// - Parameter endpoint: The request builder for this resource
    public init(_ endpoint: RequestBuilder) {
        self.endpoint = endpoint
    }
    
    /// Initialize with an endpoint and a pre-configured client (for testing)
    /// - Parameters:
    ///   - endpoint: The request builder for this resource
    ///   - client: A pre-configured network client
    public init(_ endpoint: RequestBuilder, client: URLSessionNetworkClient) {
        self.endpoint = endpoint
        self.client = client
    }
    
    /// Fetch the resource
    /// - Throws: `NetworkError` if the request fails or if the network client is not configured
    public func fetch() async throws -> T {
        let resolvedClient = try getClient()
        return try await resolvedClient.request(endpoint)
    }
    
    private func getClient() throws -> URLSessionNetworkClient {
        if let existingClient = client {
            return existingClient
        }
        
        guard let resolved = DI.shared.tryResolve(URLSessionNetworkClient.self) else {
            throw NetworkError.underlying("URLSessionNetworkClient not registered in DI container. Call DI.configure() first.")
        }
        
        client = resolved
        return resolved
    }
}

// MARK: - List Service

/// Generic Network Service for fetching lists
public final class GenericListService<T: Decodable>: @unchecked Sendable {
    
    private let endpoint: RequestBuilder
    private var client: URLSessionNetworkClient?
    
    /// Initialize with an endpoint
    /// - Parameter endpoint: The request builder for this resource
    public init(_ endpoint: RequestBuilder) {
        self.endpoint = endpoint
    }
    
    /// Initialize with an endpoint and a pre-configured client (for testing)
    /// - Parameters:
    ///   - endpoint: The request builder for this resource
    ///   - client: A pre-configured network client
    public init(_ endpoint: RequestBuilder, client: URLSessionNetworkClient) {
        self.endpoint = endpoint
        self.client = client
    }
    
    /// Fetch the list of resources
    /// - Throws: `NetworkError` if the request fails or if the network client is not configured
    public func fetch() async throws -> [T] {
        let resolvedClient = try getClient()
        let response: ArrayResponse<T> = try await resolvedClient.request(endpoint)
        return response.items
    }
    
    private func getClient() throws -> URLSessionNetworkClient {
        if let existingClient = client {
            return existingClient
        }
        
        guard let resolved = DI.shared.tryResolve(URLSessionNetworkClient.self) else {
            throw NetworkError.underlying("URLSessionNetworkClient not registered in DI container. Call DI.configure() first.")
        }
        
        client = resolved
        return resolved
    }
}
