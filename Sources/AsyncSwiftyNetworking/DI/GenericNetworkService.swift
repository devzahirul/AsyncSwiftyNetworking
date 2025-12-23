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
    
    /// Fetch the resource
    public func fetch() async throws -> T {
        let resolvedClient = getClient()
        return try await resolvedClient.request(endpoint)
    }
    
    private func getClient() -> URLSessionNetworkClient {
        if client == nil {
            client = DI.shared.resolve(URLSessionNetworkClient.self)
        }
        return client!
    }
}

// MARK: - List Service

/// Generic Network Service for fetching lists
public final class GenericListService<T: Decodable>: @unchecked Sendable {
    
    private let endpoint: RequestBuilder
    private var client: URLSessionNetworkClient?
    
    public init(_ endpoint: RequestBuilder) {
        self.endpoint = endpoint
    }
    
    public func fetch() async throws -> [T] {
        let resolvedClient = getClient()
        let response: ArrayResponse<T> = try await resolvedClient.request(endpoint)
        return response.items
    }
    
    private func getClient() -> URLSessionNetworkClient {
        if client == nil {
            client = DI.shared.resolve(URLSessionNetworkClient.self)
        }
        return client!
    }
}
